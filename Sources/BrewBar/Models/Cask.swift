import Foundation

struct Cask: Identifiable, Sendable {
    var id: String { token }
    let token: String
    let name: String
    let version: String
    let latestVersion: String?
    let description: String?
    let homepage: String?
    let outdated: Bool
    let tap: String?
    let autoUpdates: Bool
}
