import Foundation

actor BrewDataService {
    private let process = BrewProcess()
    private let decoder = JSONDecoder()

    // MARK: - Fetch installed packages

    func fetchInstalled() async throws -> (formulae: [Formula], casks: [Cask]) {
        // Fetch formulae and casks separately. A broken cask formula (e.g. one that calls
        // a removed DSL method like `discontinued`) can cause `brew info --json=v2 --installed`
        // to exit non-zero and return nothing. Splitting on --formula / --cask isolates that
        // failure so formulae always load even when one cask's Ruby formula is broken.
        async let formulaeData = process.run(["info", "--json=v2", "--installed", "--formula"])
        async let casksData = process.runAllowingFailure(["info", "--json=v2", "--installed", "--cask"])

        let fData = try await formulaeData
        let cData = await casksData

        let fJson = try decoder.decode(BrewInfoJSON.self, from: fData)
        let formulae = fJson.formulae.map { $0.toFormula() }.sorted { $0.name < $1.name }

        let casks: [Cask]
        if let cJson = try? decoder.decode(BrewInfoJSON.self, from: cData) {
            casks = cJson.casks.map { $0.toCask() }.sorted { $0.token < $1.token }
        } else {
            casks = []
        }

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

    static let trackedTools = [
        "uv", "bun", "mise", "fnm", "volta", "pyenv", "rbenv", "rustup", "goenv", "jenv", "chruby", "nvm"
    ]

    func resolveToolPaths(for installedNames: Set<String>) -> [String: String] {
        let fileManager = FileManager.default
        let searchPaths = ["/opt/homebrew/bin", "/usr/local/bin"]

        var paths: [String: String] = [:]
        for tool in Self.trackedTools where installedNames.contains(tool) {
            for dir in searchPaths {
                let fullPath = "\(dir)/\(tool)"
                if fileManager.fileExists(atPath: fullPath) {
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

    func upgradeMultiple(formulae: [String], casks: [String]) async throws -> String {
        var output = ""
        if !formulae.isEmpty {
            output += try await process.runString(["upgrade"] + formulae)
        }
        if !casks.isEmpty {
            if !output.isEmpty { output += "\n" }
            output += try await process.runString(["upgrade", "--cask"] + casks)
        }
        return output
    }

    func fetchDepTree(for name: String) async throws -> String {
        try await process.runString(["deps", "--tree", name])
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
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: logPath) else {
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
        async let formulaeOutput = process.runStringAllowingFailure(["search", "--formula", query])
        async let casksOutput = process.runStringAllowingFailure(["search", "--cask", query])

        let (fOut, cOut) = try await (formulaeOutput, casksOutput)

        let formulae = fOut.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==>") }
        let casks = cOut.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==>") }

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

    // MARK: - Doctor

    func doctor() async throws -> String {
        try await process.runStringAllowingFailure(["doctor", "--quiet"])
    }

    // MARK: - Taps

    func fetchTaps() async throws -> [String] {
        let output = try await process.runString(["tap"])
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .sorted()
    }

    func addTap(_ name: String) async throws -> String {
        try await process.runString(["tap", name])
    }

    func removeTap(_ name: String) async throws -> String {
        try await process.runString(["untap", name])
    }

    // MARK: - Bundle

    func exportBundle(to path: String) async throws -> String {
        try await process.runString(["bundle", "dump", "--force", "--file=\(path)"])
    }

    func installBundle(at path: String) async throws -> String {
        try await process.runString(["bundle", "install", "--file=\(path)"])
    }

    // MARK: - Analytics

    func fetchAnalytics() async throws -> BrewAnalytics {
        let formulaeURL = URL(string: "https://formulae.brew.sh/api/analytics/install/homebrew-core/30d.json")!
        let casksURL = URL(string: "https://formulae.brew.sh/api/analytics/cask-install/homebrew-cask/30d.json")!

        async let formulaeResponse = URLSession.shared.data(from: formulaeURL)
        async let casksResponse = URLSession.shared.data(from: casksURL)

        let (fData, cData) = try await (formulaeResponse, casksResponse)

        var analytics = BrewAnalytics()

        if let fJson = try? decoder.decode(AnalyticsResponseJSON.self, from: fData.0) {
            for (name, entries) in fJson.entries {
                analytics.formulaInstalls[name] = entries.reduce(0) { $0 + $1.parsedCount }
            }
        }

        if let cJson = try? decoder.decode(AnalyticsResponseJSON.self, from: cData.0) {
            for (name, entries) in cJson.entries {
                analytics.caskInstalls[name] = entries.reduce(0) { $0 + $1.parsedCount }
            }
        }

        return analytics
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
