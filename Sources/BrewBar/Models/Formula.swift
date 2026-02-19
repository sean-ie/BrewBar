import Foundation

struct Formula: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let fullName: String
    let version: String
    let latestVersion: String?
    let description: String?
    let homepage: String?
    let outdated: Bool
    let pinned: Bool
    let license: String?
    let tap: String?
    let dependencies: [String]
    let buildDependencies: [String]
    let installedOnRequest: Bool
}
