import SwiftUI

@main
struct BrewBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // AppDelegate owns the NSStatusItem, NSPopover, and click handling.
        // This empty Settings scene satisfies the App protocol requirement
        // and keeps the process alive without showing any window.
        Settings { EmptyView() }
    }
}
