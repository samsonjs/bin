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

  func setMode(width: Int, height: Int) {
    // Prefer 1x modes (pixel size == point size) so 3840x2160 is a real 4K
    // desktop, then the highest refresh rate.
    let candidates = modes
      .filter { $0.pixelWidth == width && $0.pixelHeight == height && $0.isUsableForDesktopGUI() }
      .sorted { a, b in
        if (a.width == a.pixelWidth) != (b.width == b.pixelWidth) { return a.width == a.pixelWidth }
        return a.refreshRate > b.refreshRate
      }
    guard let mode = candidates.first else {
      die("no \(width)x\(height) mode on \(name); run `modes` to see what's available")
    }
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
  let wasDynamic = d.dynamicEnabled
  if wasDynamic { d.setDynamic(false) }
  d.setMode(width: w, height: h)
  d.setDynamic(true)
  print("\(d.name): \(d.currentMode.map(describe) ?? "?"), dynamic resolution \(d.dynamicEnabled ? "on" : "off")")

default:
  die("unknown command \(command); use list, modes, dynamic on|off, set WxH, or fix [WxH]")
}
