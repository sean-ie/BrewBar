import AppKit
import Foundation
import SwiftUI

struct UninstallConfirmation {
    let packages: [String]
    let dependents: [String]
}

struct CleanupPreview {
    let fileCount: Int
    let details: String
}

@MainActor
@Observable
final class BrewViewModel {
    var info = BrewInfo()
    var isLoading = false
    var error: String?
    var actionInProgress: String?
    var lastActionOutput: String?

    // Search & install state
    var searchResults: (formulae: [String], casks: [String]) = ([], [])
    var isSearching = false

    // Uninstall confirmation state
    var confirmingUninstall: UninstallConfirmation?

    // Cleanup state
    var cleanupPreview: CleanupPreview?
    var showNothingToClean = false

    // Bundle state
    var bundle: BrewBundle?

    private let service = BrewDataService()
    private var refreshTimer: Timer?
    private let bundlePathKey = "bundleFilePath"

    init() {
        startAutoRefresh()
        loadPersistedBundle()
    }

    // MARK: - Refresh

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        Task {
            do {
                async let installed = service.fetchInstalled()
                async let outdated = service.fetchOutdated()
                async let services = service.fetchServices()
                async let config = service.fetchConfig()

                let (installedResult, outdatedResult, servicesResult, configResult) = try await (installed, outdated, services, config)

                info.formulae = installedResult.formulae
                info.casks = installedResult.casks
                info.outdatedFormulae = outdatedResult.formulae
                info.outdatedCasks = outdatedResult.casks
                info.services = servicesResult
                info.brewConfig = configResult
                info.redundantPackages = detectRedundancies(in: installedResult.formulae)
                let installedNames = Set(installedResult.formulae.map(\.name))
                info.toolPaths = await service.resolveToolPaths(for: installedNames)

                if let existing = bundle {
                    bundle = BrewBundle(
                        path: existing.path,
                        displayName: existing.displayName,
                        entries: checkBundleStatus(existing.entries)
                    )
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Upgrade actions

    func upgradeAll() {
        performAction("Upgrading all packages...") {
            try await self.service.upgradeAll()
        }
    }

    func upgrade(package name: String, isCask: Bool = false) {
        performAction("Upgrading \(name)...") {
            try await self.service.upgrade(package: name, isCask: isCask)
        }
    }

    // MARK: - Search & Install

    func searchBrewPackages(_ query: String) {
        guard !query.isEmpty else {
            searchResults = ([], [])
            isSearching = false
            return
        }
        isSearching = true
        Task {
            do {
                let results = try await service.searchPackages(query)
                // Filter out already-installed packages
                let installedFormulae = Set(info.formulae.map(\.name))
                let installedCasks = Set(info.casks.map(\.token))
                searchResults = (
                    formulae: results.formulae.filter { !installedFormulae.contains($0) },
                    casks: results.casks.filter { !installedCasks.contains($0) }
                )
            } catch {
                self.error = error.localizedDescription
                searchResults = ([], [])
            }
            isSearching = false
        }
    }

    func clearSearchResults() {
        searchResults = ([], [])
    }

    func install(package name: String, isCask: Bool) {
        performAction("Installing \(name)...") {
            try await self.service.install(package: name, isCask: isCask)
        }
    }

    // MARK: - Uninstall actions

    func uninstall(package name: String) {
        let deps = dependentsOf(name)
        if deps.isEmpty {
            forceUninstall(package: name)
        } else {
            confirmingUninstall = UninstallConfirmation(packages: [name], dependents: deps)
        }
    }

    func uninstallAll(packages names: [String]) {
        let allDeps = Set(names.flatMap { dependentsOf($0) }).subtracting(names).sorted()
        if allDeps.isEmpty {
            forceUninstallAll(packages: names)
        } else {
            confirmingUninstall = UninstallConfirmation(packages: names, dependents: allDeps)
        }
    }

    func confirmUninstall() {
        guard let confirmation = confirmingUninstall else { return }
        confirmingUninstall = nil
        if confirmation.packages.count == 1 {
            forceUninstall(package: confirmation.packages[0])
        } else {
            forceUninstallAll(packages: confirmation.packages)
        }
    }

    private func forceUninstall(package name: String) {
        performAction("Uninstalling \(name)...") {
            try await self.service.uninstall(package: name, ignoreDependencies: true)
        }
    }

    private func forceUninstallAll(packages names: [String]) {
        let label = names.count == 1 ? names[0] : "\(names.count) packages"
        performAction("Uninstalling \(label)...") {
            try await self.service.uninstall(packages: names, ignoreDependencies: true)
        }
    }

    private func dependentsOf(_ name: String) -> [String] {
        var reverseDeps: [String: [String]] = [:]
        for formula in info.formulae {
            for dep in formula.dependencies {
                reverseDeps[dep, default: []].append(formula.name)
            }
        }
        return reverseDeps[name, default: []].sorted()
    }

    // MARK: - Pin/Unpin

    func pin(package name: String) {
        performAction("Pinning \(name)...") {
            try await self.service.pin(package: name)
        }
    }

    func unpin(package name: String) {
        performAction("Unpinning \(name)...") {
            try await self.service.unpin(package: name)
        }
    }

    // MARK: - Cleanup

    func previewCleanup() {
        actionInProgress = "Checking for cleanable files..."
        Task {
            do {
                let output = try await service.cleanupDryRun()
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    showNothingToClean = true
                } else {
                    let lines = trimmed.components(separatedBy: .newlines)
                        .filter { !$0.isEmpty }
                    cleanupPreview = CleanupPreview(
                        fileCount: lines.count,
                        details: trimmed
                    )
                }
            } catch {
                self.error = error.localizedDescription
            }
            actionInProgress = nil
        }
    }

    func confirmCleanup() {
        cleanupPreview = nil
        performAction("Cleaning up...") {
            try await self.service.cleanup()
        }
    }

    // MARK: - Service actions

    var serviceLog: (name: String, content: String)?

    func fetchServiceLog(_ name: String) {
        actionInProgress = "Loading log for \(name)..."
        Task {
            do {
                let log = try await service.fetchServiceLog(name)
                serviceLog = (name: name, content: log)
            } catch {
                self.error = error.localizedDescription
            }
            actionInProgress = nil
        }
    }

    func dismissServiceLog() {
        serviceLog = nil
    }

    func startService(_ name: String) {
        performAction("Starting \(name)...") {
            try await self.service.startService(name)
        }
    }

    func stopService(_ name: String) {
        performAction("Stopping \(name)...") {
            try await self.service.stopService(name)
        }
    }

    func restartService(_ name: String) {
        performAction("Restarting \(name)...") {
            try await self.service.restartService(name)
        }
    }

    func dismissOutput() {
        lastActionOutput = nil
    }

    // MARK: - Private

    private func performAction(_ description: String, action: @escaping @Sendable () async throws -> String) {
        actionInProgress = description
        lastActionOutput = nil
        Task {
            do {
                let output = try await action()
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    lastActionOutput = trimmed
                }
            } catch {
                self.error = error.localizedDescription
            }
            actionInProgress = nil
            refresh()
        }
    }

    // MARK: - Bundle

    func exportBundle() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Brewfile"
        panel.title = "Export Brewfile"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        performAction("Exporting Brewfile...") {
            try await self.service.exportBundle(to: url.path)
        }
    }

    func loadBundle() {
        let panel = NSOpenPanel()
        panel.title = "Load Brewfile"
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let entries = try parseBrewfile(at: url.path)
            bundle = BrewBundle(
                path: url.path,
                displayName: url.lastPathComponent,
                entries: checkBundleStatus(entries)
            )
            UserDefaults.standard.set(url.path, forKey: bundlePathKey)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func installBundleMissing() {
        guard let b = bundle else { return }
        performAction("Installing missing Brewfile entries...") {
            try await self.service.installBundle(at: b.path)
        }
    }

    func clearBundle() {
        bundle = nil
        UserDefaults.standard.removeObject(forKey: bundlePathKey)
    }

    private func loadPersistedBundle() {
        guard let path = UserDefaults.standard.string(forKey: bundlePathKey) else { return }
        guard FileManager.default.fileExists(atPath: path) else {
            UserDefaults.standard.removeObject(forKey: bundlePathKey)
            return
        }
        do {
            let entries = try parseBrewfile(at: path)
            let url = URL(fileURLWithPath: path)
            bundle = BrewBundle(
                path: path,
                displayName: url.lastPathComponent,
                entries: checkBundleStatus(entries)
            )
        } catch { /* silently skip */ }
    }

    private func parseBrewfile(at path: String) throws -> [BundleEntry] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        var entries: [BundleEntry] = []
        let pattern = #/^(brew|cask|tap|mas|vscode|whalebrew)\s+"([^"]+)"/#
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), !trimmed.isEmpty else { continue }
            if let m = trimmed.firstMatch(of: pattern) {
                let type = BundleEntry.EntryType(rawValue: String(m.1)) ?? .brew
                entries.append(BundleEntry(type: type, name: String(m.2), isInstalled: false))
            }
        }
        return entries
    }

    private func checkBundleStatus(_ entries: [BundleEntry]) -> [BundleEntry] {
        let formulaeNames     = Set(info.formulae.map(\.name))
        let formulaeFullNames = Set(info.formulae.map(\.fullName))
        let casksSet          = Set(info.casks.map(\.token))
        return entries.map { entry in
            var e = entry
            switch e.type {
            case .brew:
                // Brewfile may use the short name ("bun") or the full tap path ("oven-sh/bun/bun")
                e.isInstalled = formulaeNames.contains(e.name) || formulaeFullNames.contains(e.name)
            case .cask:
                e.isInstalled = casksSet.contains(e.name)
            default:
                e.isInstalled = true   // taps/mas/vscode not checked — shown neutral
            }
            return e
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}
