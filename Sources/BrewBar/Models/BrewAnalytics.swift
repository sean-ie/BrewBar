import Foundation

// MARK: - Analytics model

struct BrewAnalytics: Sendable {
    var formulaInstalls: [String: Int] = [:]  // name -> 30d install count
    var caskInstalls: [String: Int] = [:]     // token -> 30d install count
}

// MARK: - JSON DTOs (internal so BrewDataService can use them)

struct AnalyticsResponseJSON: Decodable {
    let entries: [String: [AnalyticsEntryJSON]]

    enum CodingKeys: String, CodingKey {
        case formulae
        case casks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let formulae = try? container.decode([String: [AnalyticsEntryJSON]].self, forKey: .formulae) {
            entries = formulae
        } else if let casks = try? container.decode([String: [AnalyticsEntryJSON]].self, forKey: .casks) {
            entries = casks
        } else {
            entries = [:]
        }
    }
}

struct AnalyticsEntryJSON: Decodable {
    let count: String
    var parsedCount: Int { Int(count.replacingOccurrences(of: ",", with: "")) ?? 0 }
}
