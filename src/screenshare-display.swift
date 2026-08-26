// Fixes the Screen Sharing Virtual Display getting stuck at 1920x1080 when
// "Dynamic resolution" is on: turn dynamic resolution off, set the mode, turn
// it back on. Uses the same private SkyLight calls System Settings does.
//
// Usage:
//   screenshare-display                 # fix: dynamic off -> 3840x2160 -> dynamic on
//   screenshare-display fix [WxH]       # same, with a different target size
//   screenshare-display list            # all displays with dynamic-resolution state
//   screenshare-display modes           # modes available on the virtual display
//   screenshare-display dynamic on|off  # toggle dynamic resolution only
//   screenshare-display set WxH         # set the mode only

import AppKit
import CoreGraphics
import Foundation

typealias SupportsFn = @convention(c) (UInt32) -> Bool
typealias IsEnabledFn = @convention(c) (UInt32) -> Bool
typealias SetEnabledFn = @convention(c) (UInt32, Bool) -> Int32

enum SkyLight {
  static let handle: UnsafeMutableRawPointer = {
    guard let h = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW) else {
      die("could not load SkyLight: \(String(cString: dlerror()))")
    }
    return h
  }()

  static func sym<T>(_ name: String, as type: T.Type) -> T {
    guard let p = dlsym(handle, name) else { die("missing symbol \(name)") }
    return unsafeBitCast(p, to: type)
  }

  static let supportsDynamicGeometry = sym("SLSDisplaySupportsDynamicGeometry", as: SupportsFn.self)
  static let isDynamicGeometryEnabled = sym("SLSDisplayIsDynamicGeometryEnabled", as: IsEnabledFn.self)
  static let setDynamicGeometryEnabled = sym("SLSDisplaySetDynamicGeometryEnabled", as: SetEnabledFn.self)
}

func die(_ message: String) -> Never {
  FileHandle.standardError.write("screenshare-display: \(message)\n".data(using: .utf8)!)
  exit(1)
}

struct Display {
  let id: CGDirectDisplayID
  let name: String

  var supportsDynamic: Bool { SkyLight.supportsDynamicGeometry(id) }
  var dynamicEnabled: Bool { SkyLight.isDynamicGeometryEnabled(id) }
  var currentMode: CGDisplayMode? { CGDisplayCopyDisplayMode(id) }

  var modes: [CGDisplayMode] {
    let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
    return (CGDisplayCopyAllDisplayModes(id, options) as? [CGDisplayMode]) ?? []
  }

  static func all() -> [Display] {
    var count: UInt32 = 0
    var ids = [CGDirectDisplayID](repeating: 0, count: 16)
    CGGetOnlineDisplayList(UInt32(ids.count), &ids, &count)
    let names = Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
      (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID).map { ($0, screen.localizedName) }
    })
    return ids.prefix(Int(count)).map { Display(id: $0, name: names[$0] ?? "Display \($0)") }
  }

  /// The Screen Sharing Virtual Display is the only one that supports dynamic
  /// resolution, so that's a more reliable signal than its localized name.
  static func virtual() -> Display {
    let displays = all()
    if let d = displays.first(where: { $0.supportsDynamic }) { return d }
    if let d = displays.first(where: { $0.name.localizedCaseInsensitiveContains("Screen Sharing") }) { return d }
    die("no Screen Sharing Virtual Display found (is a screen sharing session active?)")
  }

  func setDynamic(_ enabled: Bool) {
    let err = SkyLight.setDynamicGeometryEnabled(id, enabled)
    guard err == 0 else { die("SLSDisplaySetDynamicGeometryEnabled failed with error \(err)") }
  }

  /// Prefers 1x modes (pixel size == point size) so 3840x2160 is a real 4K
  /// desktop, then the highest refresh rate.
  func findMode(width: Int, height: Int) -> CGDisplayMode? {
    modes
      .filter { $0.pixelWidth == width && $0.pixelHeight == height && $0.isUsableForDesktopGUI() }
      .sorted { a, b in
        if (a.width == a.pixelWidth) != (b.width == b.pixelWidth) { return a.width == a.pixelWidth }
        return a.refreshRate > b.refreshRate
      }
      .first
  }

  /// While dynamic resolution is active the display only advertises modes
  /// shaped like the viewer, and the full list comes back a moment after it's
  /// turned off.
  func waitForMode(width: Int, height: Int, timeout: TimeInterval = 5) -> CGDisplayMode? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let mode = findMode(width: width, height: height) { return mode }
      usleep(100_000)
    }
    return nil
  }

  func setMode(width: Int, height: Int) {
    guard let mode = waitForMode(width: width, height: height) else {
      die("no \(width)x\(height) mode on \(name); run `modes` to see what's available")
    }
    setMode(mode)
  }

  func setMode(_ mode: CGDisplayMode) {
    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success,
          CGConfigureDisplayWithDisplayMode(config, id, mode, nil) == .success,
          CGCompleteDisplayConfiguration(config, .permanently) == .success
    else {
      CGCancelDisplayConfiguration(config)
      die("failed to set mode on \(name)")
    }
  }
}

extension Display {
  func waitForCurrentMode(width: Int, height: Int, timeout: TimeInterval = 5) {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let m = currentMode, m.pixelWidth == width, m.pixelHeight == height { return }
      usleep(100_000)
    }
    die("mode change to \(width)x\(height) on \(name) didn't take within \(Int(timeout))s")
  }

  /// Returns true once dynamic resolution has read back as enabled for
  /// `stableFor` seconds straight, re-enabling it whenever it flips off.
  func enableDynamicUntilStable(stableFor: TimeInterval = 2, timeout: TimeInterval = 15) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    var onSince: Date?
    while Date() < deadline {
      if dynamicEnabled {
        onSince = onSince ?? Date()
        if Date().timeIntervalSince(onSince!) >= stableFor { return true }
      } else {
        onSince = nil
        setDynamic(true)
      }
      usleep(250_000)
    }
    return false
  }
}

func describe(_ mode: CGDisplayMode) -> String {
  let scale = mode.pixelWidth == mode.width ? "1x" : "2x"
  return "\(mode.pixelWidth)x\(mode.pixelHeight) @ \(Int(mode.refreshRate))Hz \(scale) (\(mode.width)x\(mode.height) points)"
}

func parseSize(_ s: String) -> (Int, Int) {
  let parts = s.lowercased().split(separator: "x").compactMap { Int($0) }
  guard parts.count == 2 else { die("expected a size like 3840x2160, got \(s)") }
  return (parts[0], parts[1])
}

var args = Array(CommandLine.arguments.dropFirst())
let command = args.isEmpty ? "fix" : args.removeFirst()

switch command {
case "list":
  for d in Display.all() {
    let mode = d.currentMode.map(describe) ?? "?"
    let dynamic = d.supportsDynamic ? (d.dynamicEnabled ? "on" : "off") : "unsupported"
    print("\(d.id)\t\(d.name)\t\(mode)\tdynamic resolution: \(dynamic)")
  }

case "modes":
  let d = Display.virtual()
  let current = d.currentMode?.ioDisplayModeID
  for m in d.modes.sorted(by: { ($0.pixelWidth, $0.pixelHeight, $0.refreshRate) > ($1.pixelWidth, $1.pixelHeight, $1.refreshRate) }) {
    print("\(m.ioDisplayModeID == current ? "*" : " ") \(describe(m))")
  }

case "dynamic":
  guard let flag = args.first, ["on", "off"].contains(flag) else { die("usage: dynamic on|off") }
  Display.virtual().setDynamic(flag == "on")

case "set":
  guard let size = args.first else { die("usage: set WxH") }
  let (w, h) = parseSize(size)
  Display.virtual().setMode(width: w, height: h)

case "fix":
  let (w, h) = parseSize(args.first ?? "3840x2160")
  let d = Display.virtual()
  if d.dynamicEnabled { d.setDynamic(false) }
  guard let mode = d.waitForMode(width: w, height: h) else {
    d.setDynamic(true)
    die("no \(w)x\(h) mode on \(d.name); run `modes` to see what's available")
  }
  d.setMode(mode)
  // WindowServer keeps reconfiguring for a few seconds after the mode change
  // and reverts the flag while it does, so re-assert it until it has stayed
  // on for a while.
  d.waitForCurrentMode(width: w, height: h)
  let stuck = d.enableDynamicUntilStable()
  let state = stuck ? "on" : "off (failed to re-enable)"
  print("\(d.name): \(d.currentMode.map(describe) ?? "?"), dynamic resolution \(state)")
  if !stuck { exit(1) }

default:
  die("unknown command \(command); use list, modes, dynamic on|off, set WxH, or fix [WxH]")
}
