import Foundation

// MARK: - Aggregate model

struct BrewInfo: Sendable {
    var formulae: [Formula] = []
    var casks: [Cask] = []
    var outdatedFormulae: [Formula] = []
    var outdatedCasks: [Cask] = []
    var services: [BrewService] = []
    var brewConfig: [String: String] = [:]
    var redundantPackages: [RedundantPackage] = []
    var toolPaths: [String: String] = [:]  // tool name → binary path
    var taps: [String] = []
}

// MARK: - JSON DTOs for `brew info --json=v2 --installed`

struct BrewInfoJSON: Decodable, Sendable {
    let formulae: [FormulaJSON]
    let casks: [CaskJSON]
}

struct FormulaJSON: Decodable, Sendable {
    let name: String
    let full_name: String
    let desc: String?
    let homepage: String?
    let installed: [FormulaInstalled]
    let outdated: Bool
    let pinned: Bool
    let license: String?
    let tap: String?
    let dependencies: [String]?
    let build_dependencies: [String]?

    struct FormulaInstalled: Decodable, Sendable {
        let version: String
        let installed_on_request: Bool?
    }

    func toFormula() -> Formula {
        Formula(
            name: name,
            fullName: full_name,
            version: installed.first?.version ?? "unknown",
            latestVersion: nil,
            description: desc,
            homepage: homepage,
            outdated: outdated,
            pinned: pinned,
            license: license,
            tap: tap,
            dependencies: dependencies ?? [],
            buildDependencies: build_dependencies ?? [],
            installedOnRequest: installed.first?.installed_on_request ?? true
        )
    }
}

struct CaskJSON: Decodable, Sendable {
    let token: String
    let name: [String]
    let desc: String?
    let homepage: String?
    let installed: String?
    let outdated: Bool
    let tap: String?
    let auto_updates: Bool?

    func toCask() -> Cask {
        Cask(
            token: token,
            name: name.first ?? token,
            version: installed ?? "unknown",
            latestVersion: nil,
            description: desc,
            homepage: homepage,
            outdated: outdated,
            tap: tap,
            autoUpdates: auto_updates ?? false
        )
    }
}

// MARK: - JSON DTOs for `brew outdated --json=v2`

struct BrewOutdatedJSON: Decodable, Sendable {
    let formulae: [OutdatedFormulaJSON]
    let casks: [OutdatedCaskJSON]
}

struct OutdatedFormulaJSON: Decodable, Sendable {
    let name: String
    let installed_versions: [String]
    let current_version: String
    let pinned: Bool
    let pinned_version: String?

    func toFormula() -> Formula {
        Formula(
            name: name,
            fullName: name,
            version: installed_versions.first ?? "unknown",
            latestVersion: current_version,
            description: nil,
            homepage: nil,
            outdated: true,
            pinned: pinned,
            license: nil,
            tap: nil,
            dependencies: [],
            buildDependencies: [],
            installedOnRequest: true
        )
    }
}

struct OutdatedCaskJSON: Decodable, Sendable {
    let name: String
    let installed_versions: [String]
    let current_version: String

    func toCask() -> Cask {
        Cask(
            token: name,
            name: name,
            version: installed_versions.first ?? "unknown",
            latestVersion: current_version,
            description: nil,
            homepage: nil,
            outdated: true,
            tap: nil,
            autoUpdates: false
        )
    }
}

// MARK: - JSON DTOs for `brew services list --json`

struct ServiceJSON: Decodable, Sendable {
    let name: String
    let status: String?
    let pid: Int?
    let exit_code: Int?
    let user: String?
    let file: String?

    func toService() -> BrewService {
        BrewService(
            name: name,
            status: .init(raw: status),
            pid: pid,
            exitCode: exit_code,
            user: user,
            file: file
        )
    }
}

struct ServiceInfoJSON: Decodable, Sendable {
    let name: String
    let log_path: String?
    let error_log_path: String?
}
