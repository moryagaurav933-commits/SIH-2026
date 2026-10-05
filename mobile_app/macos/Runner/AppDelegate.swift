import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "krishi_saarthi/permissions", binaryMessenger: controller.engine.binaryMessenger)
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "checkCamera":
          let status = AVCaptureDevice.authorizationStatus(for: .video)
          result(status == .authorized)

        case "checkMicrophone":
          let status = AVCaptureDevice.authorizationStatus(for: .audio)
          result(status == .authorized)

        case "requestCamera":
          let status = AVCaptureDevice.authorizationStatus(for: .video)
          if status == .authorized {
            result(true)
          } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
              DispatchQueue.main.async {
                result(granted)
              }
            }
          } else {
            result(false)
          }

        case "requestMicrophone":
          let status = AVCaptureDevice.authorizationStatus(for: .audio)
          if status == .authorized {
            result(true)
          } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
              DispatchQueue.main.async {
                result(granted)
              }
            }
          } else {
            result(false)
          }

        case "openSettings":
          var opened = false
          if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            opened = NSWorkspace.shared.open(url)
          }
          if !opened, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            opened = NSWorkspace.shared.open(url)
          }
          if !opened {
            if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systemsettings") ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
              NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration())
              opened = true
            }
          }
          result(opened)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
