import SwiftUI

@main
struct BrewBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrewBar", systemImage: "mug") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
