import Foundation

struct InstallRecord: Identifiable, Sendable {
    var id: String { "\(name)-\(version)" }
    let name: String
    let version: String
    let date: Date
    let isCask: Bool
}

struct BrewEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let type: EventType
    let packages: [String]

    enum EventType: String, Codable, Sendable {
        case install, upgrade, uninstall

        var label: String {
            switch self {
            case .install: "Installed"
            case .upgrade: "Upgraded"
            case .uninstall: "Uninstalled"
            }
        }

        var icon: String {
            switch self {
            case .install: "arrow.down.circle"
            case .upgrade: "arrow.up.circle"
            case .uninstall: "trash"
            }
        }
    }
}
