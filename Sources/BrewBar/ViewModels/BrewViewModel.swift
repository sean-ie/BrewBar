import Foundation
import SwiftUI

@MainActor
@Observable
final class BrewViewModel {
    var info = BrewInfo()
    var isLoading = false
    var error: String?
    var actionInProgress: String?
    var lastActionOutput: String?

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

    // MARK: - Uninstall actions

    func uninstall(package name: String) {
        performAction("Uninstalling \(name)...") {
            try await self.service.uninstall(package: name, ignoreDependencies: true)
        }
    }

    func uninstallAll(packages names: [String]) {
        let label = names.count == 1 ? names[0] : "\(names.count) packages"
        performAction("Uninstalling \(label)...") {
            try await self.service.uninstall(packages: names, ignoreDependencies: true)
        }
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
