import Foundation

struct BundleEntry: Identifiable, Sendable {
    var id: String { "\(type.rawValue):\(name)" }
    let type: EntryType
    let name: String
    var isInstalled: Bool

    enum EntryType: String, Sendable {
        case brew, cask, tap, mas, vscode, whalebrew

        var label: String {
            switch self {
            case .brew: "formula"
            case .cask: "cask"
            case .tap: "tap"
            default: rawValue
            }
        }

        // Only formulae and casks can be cross-referenced against installed packages
        var isCheckable: Bool { self == .brew || self == .cask }
    }
}

struct BrewBundle: Sendable {
    let path: String
    let displayName: String
    let entries: [BundleEntry]

    var installedCount: Int { entries.filter { $0.type.isCheckable && $0.isInstalled }.count }
    var missingCount: Int   { entries.filter { $0.type.isCheckable && !$0.isInstalled }.count }
    var checkableCount: Int { entries.filter { $0.type.isCheckable }.count }
}
