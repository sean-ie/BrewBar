import Foundation
import SwiftUI

struct UninstallConfirmation {
    let packages: [String]
    let dependents: [String]
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
    var showUninstallConfirmation: Bool {
        get { confirmingUninstall != nil }
        set { if !newValue { confirmingUninstall = nil } }
    }

    private let service = BrewDataService()
    private var refreshTimer: Timer?

    init() {
        startAutoRefresh()
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

    // MARK: - Service actions

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

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}
