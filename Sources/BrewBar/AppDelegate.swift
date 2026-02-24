import AppKit
import SwiftUI

extension Notification.Name {
    static let brewBarRefreshRequested = Notification.Name("io.brewbar.refreshRequested")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "mug", accessibilityDescription: "BrewBar")
        button.image?.isTemplate = true
        button.sendAction(on: NSEvent.EventTypeMask([.leftMouseUp, .rightMouseDown]))
        button.action = #selector(handleClick(_:))
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseDown {
            showContextMenu(for: sender)
        } else {
            togglePopover(relativeTo: sender)
        }
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu(for button: NSStatusBarButton) {
        let menu = NSMenu()

        let refresh = NSMenuItem(title: "Refresh", action: #selector(triggerRefresh), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About BrewBar", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit BrewBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    // MARK: - Menu actions

    @objc private func triggerRefresh() {
        NotificationCenter.default.post(name: .brewBarRefreshRequested, object: nil)
    }

    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationVersion: version,
            .credits: NSAttributedString(string: "A macOS menu bar companion for Homebrew.")
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}
