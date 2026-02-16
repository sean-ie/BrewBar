import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, Sendable {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
