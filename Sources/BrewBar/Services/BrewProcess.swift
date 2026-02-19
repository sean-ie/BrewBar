import Foundation

actor BrewProcess {
    private let brewPath: String

    init() {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
            self.brewPath = "/opt/homebrew/bin/brew"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/brew") {
            self.brewPath = "/usr/local/bin/brew"
        } else {
            self.brewPath = "brew"
        }
    }

    struct BrewError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    func run(_ arguments: [String]) async throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = arguments

        // Inherit PATH so brew can find its dependencies
        var env = ProcessInfo.processInfo.environment
        let homebrewPrefix = URL(fileURLWithPath: brewPath).deletingLastPathComponent().path
        if let path = env["PATH"] {
            env["PATH"] = "\(homebrewPrefix):\(path)"
        }
        process.environment = env

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        // Read pipe data BEFORE waitUntilExit to avoid deadlock when
        // output exceeds the pipe buffer size (e.g. brew info JSON).
        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw BrewError(message: "brew \(arguments.joined(separator: " ")) failed: \(errorString)")
        }

        return outputData
    }

    func runString(_ arguments: [String]) async throws -> String {
        let data = try await run(arguments)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // Captures stdout regardless of exit code — for commands like `brew doctor`
    // that exit 1 when they have output to report.
    func runStringAllowingFailure(_ arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let homebrewPrefix = URL(fileURLWithPath: brewPath).deletingLastPathComponent().path
        if let path = env["PATH"] {
            env["PATH"] = "\(homebrewPrefix):\(path)"
        }
        process.environment = env

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

        try process.run()
        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: outputData, encoding: .utf8) ?? ""
    }
}
