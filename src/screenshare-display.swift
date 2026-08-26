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
//   screenshare-display watch [WxH]     # run fix whenever the virtual display appears
//   screenshare-display install [WxH]   # run `watch` at login via a LaunchAgent
//   screenshare-display uninstall       # remove the LaunchAgent

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

struct Failure: Error, CustomStringConvertible {
  let description: String
  init(_ description: String) { self.description = description }
}

func log(_ message: String) {
  let stamp = ISO8601DateFormatter().string(from: Date())
  print("\(stamp) \(message)")
  fflush(stdout)
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
  static func virtual() throws -> Display {
    let displays = all()
    if let d = displays.first(where: { $0.supportsDynamic }) { return d }
    if let d = displays.first(where: { $0.name.localizedCaseInsensitiveContains("Screen Sharing") }) { return d }
    throw Failure("no Screen Sharing Virtual Display found (is a screen sharing session active?)")
  }

  func setDynamic(_ enabled: Bool) throws {
    let err = SkyLight.setDynamicGeometryEnabled(id, enabled)
    guard err == 0 else { throw Failure("SLSDisplaySetDynamicGeometryEnabled failed with error \(err)") }
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
  func waitForMode(width: Int, height: Int, timeout: TimeInterval = 5) throws -> CGDisplayMode {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let mode = findMode(width: width, height: height) { return mode }
      usleep(100_000)
    }
    throw Failure("no \(width)x\(height) mode on \(name); run `modes` to see what's available")
  }

  func setMode(_ mode: CGDisplayMode) throws {
    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success,
          CGConfigureDisplayWithDisplayMode(config, id, mode, nil) == .success,
          CGCompleteDisplayConfiguration(config, .permanently) == .success
    else {
      CGCancelDisplayConfiguration(config)
      throw Failure("failed to set mode on \(name)")
    }
  }

  func waitForCurrentMode(width: Int, height: Int, timeout: TimeInterval = 5) throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let m = currentMode, m.pixelWidth == width, m.pixelHeight == height { return }
      usleep(100_000)
    }
    throw Failure("mode change to \(width)x\(height) on \(name) didn't take within \(Int(timeout))s")
  }

  /// Returns true once dynamic resolution has read back as enabled for
  /// `stableFor` seconds straight, re-enabling it whenever it flips off.
  func enableDynamicUntilStable(stableFor: TimeInterval = 2, timeout: TimeInterval = 15) throws -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    var onSince: Date?
    while Date() < deadline {
      if dynamicEnabled {
        onSince = onSince ?? Date()
        if Date().timeIntervalSince(onSince!) >= stableFor { return true }
      } else {
        onSince = nil
        try setDynamic(true)
      }
      usleep(250_000)
    }
    return false
  }

  func fix(width: Int, height: Int) throws -> String {
    if dynamicEnabled { try setDynamic(false) }
    let mode: CGDisplayMode
    do {
      mode = try waitForMode(width: width, height: height)
    } catch {
      try? setDynamic(true)
      throw error
    }
    try setMode(mode)
    // WindowServer keeps reconfiguring for a few seconds after the mode change
    // and reverts the flag while it does, so re-assert it until it has stayed
    // on for a while.
    try waitForCurrentMode(width: width, height: height)
    guard try enableDynamicUntilStable() else {
      throw Failure("\(name): \(currentMode.map(describe) ?? "?"), but dynamic resolution failed to re-enable")
    }
    return "\(name): \(currentMode.map(describe) ?? "?"), dynamic resolution on"
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

// MARK: - Watching for the virtual display

/// Runs `fix` a few seconds after a dynamic-resolution-capable display is
/// added. The delay lets the display finish coming up, and pending work is
/// replaced rather than stacked so a burst of add events yields one fix.
final class Watcher {
  let width: Int
  let height: Int
  private let queue = DispatchQueue(label: "screenshare-display.fix")
  private var pending: DispatchWorkItem?

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  func displayAdded(_ id: CGDirectDisplayID) {
    guard SkyLight.supportsDynamicGeometry(id) else { return }
    log("virtual display \(id) connected, fixing in 3s")
    pending?.cancel()
    let work = DispatchWorkItem { [self] in
      do {
        let display = Display.all().first { $0.id == id } ?? Display(id: id, name: "Display \(id)")
        log(try display.fix(width: width, height: height))
      } catch {
        log("fix failed: \(error)")
      }
    }
    pending = work
    queue.asyncAfter(deadline: .now() + 3, execute: work)
  }

  func run() -> Never {
    let context = Unmanaged.passUnretained(self).toOpaque()
    CGDisplayRegisterReconfigurationCallback({ id, flags, context in
      guard flags.contains(.addFlag), let context else { return }
      Unmanaged<Watcher>.fromOpaque(context).takeUnretainedValue().displayAdded(id)
    }, context)
    log("watching for the Screen Sharing Virtual Display (target \(width)x\(height))")
    CFRunLoopRun()
    exit(0)
  }
}

// MARK: - LaunchAgent

enum LaunchAgent {
  static let label = "net.samhuri.screenshare-display"
  static let plistPath = NSHomeDirectory() + "/Library/LaunchAgents/\(label).plist"
  static let logPath = NSHomeDirectory() + "/Library/Logs/screenshare-display.log"
  static var domain: String { "gui/\(getuid())" }

  static func install(size: String) throws {
    let executable = Bundle.main.executableURL!.resolvingSymlinksInPath().path
    let plist: [String: Any] = [
      "Label": label,
      "ProgramArguments": [executable, "watch", size],
      "RunAtLoad": true,
      "KeepAlive": true,
      "StandardOutPath": logPath,
      "StandardErrorPath": logPath,
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try FileManager.default.createDirectory(atPath: (plistPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    if FileManager.default.fileExists(atPath: plistPath) { try? launchctl("bootout", "\(domain)/\(label)") }
    try data.write(to: URL(fileURLWithPath: plistPath))
    try launchctl("bootstrap", domain, plistPath)
    print("installed \(plistPath), logging to \(logPath)")
  }

  static func uninstall() throws {
    try? launchctl("bootout", "\(domain)/\(label)")
    try FileManager.default.removeItem(atPath: plistPath)
    print("removed \(plistPath)")
  }

  private static func launchctl(_ args: String...) throws {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    p.arguments = args
    try p.run()
    p.waitUntilExit()
    guard p.terminationStatus == 0 else { throw Failure("launchctl \(args.joined(separator: " ")) exited \(p.terminationStatus)") }
  }
}

// MARK: - Main

var args = Array(CommandLine.arguments.dropFirst())
let command = args.isEmpty ? "fix" : args.removeFirst()

do {
  switch command {
  case "list":
    for d in Display.all() {
      let mode = d.currentMode.map(describe) ?? "?"
      let dynamic = d.supportsDynamic ? (d.dynamicEnabled ? "on" : "off") : "unsupported"
      print("\(d.id)\t\(d.name)\t\(mode)\tdynamic resolution: \(dynamic)")
    }

  case "modes":
    let d = try Display.virtual()
    let current = d.currentMode?.ioDisplayModeID
    for m in d.modes.sorted(by: { ($0.pixelWidth, $0.pixelHeight, $0.refreshRate) > ($1.pixelWidth, $1.pixelHeight, $1.refreshRate) }) {
      print("\(m.ioDisplayModeID == current ? "*" : " ") \(describe(m))")
    }

  case "dynamic":
    guard let flag = args.first, ["on", "off"].contains(flag) else { die("usage: dynamic on|off") }
    try Display.virtual().setDynamic(flag == "on")

  case "set":
    guard let size = args.first else { die("usage: set WxH") }
    let (w, h) = parseSize(size)
    let d = try Display.virtual()
    try d.setMode(d.waitForMode(width: w, height: h))

  case "fix":
    let (w, h) = parseSize(args.first ?? "3840x2160")
    print(try Display.virtual().fix(width: w, height: h))

  case "watch":
    let (w, h) = parseSize(args.first ?? "3840x2160")
    Watcher(width: w, height: h).run()

  case "install":
    let size = args.first ?? "3840x2160"
    _ = parseSize(size)
    try LaunchAgent.install(size: size)

  case "uninstall":
    try LaunchAgent.uninstall()

  default:
    die("unknown command \(command); use list, modes, dynamic on|off, set WxH, fix [WxH], watch [WxH], install [WxH], or uninstall")
  }
} catch {
  die("\(error)")
}
