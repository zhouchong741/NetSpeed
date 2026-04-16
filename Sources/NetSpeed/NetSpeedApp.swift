import AppKit
import Foundation
import NetSpeedCore

@main
struct NetSpeedApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = NetworkSpeedMonitor(updateInterval: 1.0)
    private let statusBarController = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }

        monitor.onUpdate = { [weak self] speed in
            self?.statusBarController.update(with: speed)
        }

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
