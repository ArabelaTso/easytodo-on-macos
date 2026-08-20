import Foundation

enum TaskRepeatRule: String, CaseIterable, Identifiable {
    case none
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "No Repeat"
        case .daily:
            "Every Day"
        case .weekly:
            "Every Week"
        }
    }

    static func normalized(from rawValue: String?) -> TaskRepeatRule {
        guard let rawValue, let repeatRule = TaskRepeatRule(rawValue: rawValue) else {
            return .none
        }

        return repeatRule
    }
}
