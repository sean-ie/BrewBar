import Foundation

struct BrewService: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let status: Status
    let pid: Int?
    let exitCode: Int?
    let user: String?
    let file: String?

    enum Status: String, Sendable {
        case started
        case stopped
        case error
        case unknown

        init(raw: String?) {
            switch raw?.lowercased() {
            case "started": self = .started
            case "stopped", "none", .none: self = .stopped
            case "error": self = .error
            default: self = .unknown
            }
        }
    }
}
