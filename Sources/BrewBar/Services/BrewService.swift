import Foundation

actor BrewDataService {
    private let process = BrewProcess()
    private let decoder = JSONDecoder()

    // MARK: - Fetch installed packages

    func fetchInstalled() async throws -> (formulae: [Formula], casks: [Cask]) {
        let data = try await process.run(["info", "--json=v2", "--installed"])
        let json = try decoder.decode(BrewInfoJSON.self, from: data)
        let formulae = json.formulae.map { $0.toFormula() }.sorted { $0.name < $1.name }
        let casks = json.casks.map { $0.toCask() }.sorted { $0.token < $1.token }
        return (formulae, casks)
    }

    // MARK: - Fetch outdated packages

    func fetchOutdated() async throws -> (formulae: [Formula], casks: [Cask]) {
        let data = try await process.run(["outdated", "--json=v2"])
        let json = try decoder.decode(BrewOutdatedJSON.self, from: data)
        let formulae = json.formulae.map { $0.toFormula() }.sorted { $0.name < $1.name }
        let casks = json.casks.map { $0.toCask() }.sorted { $0.token < $1.token }
        return (formulae, casks)
    }

    // MARK: - Fetch services

    func fetchServices() async throws -> [BrewService] {
        let data = try await process.run(["services", "list", "--json"])
        let json = try decoder.decode([ServiceJSON].self, from: data)
        return json.map { $0.toService() }.sorted { $0.name < $1.name }
    }

    // MARK: - Fetch brew config

    func fetchConfig() async throws -> [String: String] {
        let output = try await process.runString(["config"])
        var config: [String: String] = [:]
        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            config[key] = value
        }
        return config
    }

    // MARK: - Resolve tool paths

    static let trackedTools = ["uv", "bun", "mise", "fnm", "volta", "pyenv", "rbenv", "rustup", "goenv", "jenv", "chruby", "nvm"]

    func resolveToolPaths(for installedNames: Set<String>) -> [String: String] {
        let fm = FileManager.default
        let searchPaths = ["/opt/homebrew/bin", "/usr/local/bin"]

        var paths: [String: String] = [:]
        for tool in Self.trackedTools where installedNames.contains(tool) {
            for dir in searchPaths {
                let fullPath = "\(dir)/\(tool)"
                if fm.fileExists(atPath: fullPath) {
                    paths[tool] = fullPath
                    break
                }
            }
        }
        return paths
    }

    // MARK: - Actions

    func upgradeAll() async throws -> String {
        try await process.runString(["upgrade"])
    }

    func upgrade(package name: String, isCask: Bool = false) async throws -> String {
        var args = ["upgrade", name]
        if isCask { args.insert("--cask", at: 1) }
        return try await process.runString(args)
    }

    func startService(_ name: String) async throws -> String {
        try await process.runString(["services", "start", name])
    }

    func stopService(_ name: String) async throws -> String {
        try await process.runString(["services", "stop", name])
    }

    func restartService(_ name: String) async throws -> String {
        try await process.runString(["services", "restart", name])
    }

    // MARK: - Service info

    func fetchServiceLog(_ name: String) async throws -> String {
        let data = try await process.run(["services", "info", name, "--json"])
        let infoArray: [ServiceInfoJSON] = try decoder.decode([ServiceInfoJSON].self, from: data)
        guard let svcInfo = infoArray.first, let logPath = svcInfo.log_path else {
            return "No log file found for \(name)."
        }
        let fm = FileManager.default
        guard fm.fileExists(atPath: logPath) else {
            return "Log file not found at \(logPath)."
        }
        let url = URL(fileURLWithPath: logPath)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: CharacterSet.newlines)
        // Return last 50 lines
        let tail = lines.suffix(50).joined(separator: "\n")
        return tail.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
            ? "Log file is empty."
            : tail
    }

    // MARK: - Search & Install

    func searchPackages(_ query: String) async throws -> (formulae: [String], casks: [String]) {
        async let formulaeOutput = process.runString(["search", "--formula", query])
        async let casksOutput = process.runString(["search", "--cask", query])

        let (fOut, cOut) = try await (formulaeOutput, casksOutput)

        let formulae = fOut.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let casks = cOut.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return (formulae, casks)
    }

    func install(package name: String, isCask: Bool) async throws -> String {
        var args = ["install", name]
        if isCask { args.insert("--cask", at: 1) }
        return try await process.runString(args)
    }

    // MARK: - Pin/Unpin

    func pin(package name: String) async throws -> String {
        try await process.runString(["pin", name])
    }

    func unpin(package name: String) async throws -> String {
        try await process.runString(["unpin", name])
    }

    // MARK: - Cleanup

    func cleanupDryRun() async throws -> String {
        try await process.runString(["cleanup", "--prune=all", "-n"])
    }

    func cleanup() async throws -> String {
        try await process.runString(["cleanup", "--prune=all"])
    }

    // MARK: - Bundle

    func exportBundle(to path: String) async throws -> String {
        try await process.runString(["bundle", "dump", "--force", "--file=\(path)"])
    }

    func installBundle(at path: String) async throws -> String {
        try await process.runString(["bundle", "install", "--file=\(path)"])
    }

    // MARK: - Uninstall

    func uninstall(package name: String, ignoreDependencies: Bool = false) async throws -> String {
        var args = ["uninstall", name]
        if ignoreDependencies { args.insert("--ignore-dependencies", at: 1) }
        return try await process.runString(args)
    }

    func uninstall(packages names: [String], ignoreDependencies: Bool = false) async throws -> String {
        var args = ["uninstall"] + names
        if ignoreDependencies { args.insert("--ignore-dependencies", at: 1) }
        return try await process.runString(args)
    }
}
