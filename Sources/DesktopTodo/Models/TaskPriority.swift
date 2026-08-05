import SwiftUI

enum TaskPriority: String, CaseIterable, Identifiable {
    case importantUrgent
    case urgentNotImportant
    case notUrgentImportant
    case notUrgentNotImportant

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .importantUrgent:
            Color(red: 0.78, green: 0.18, blue: 0.15)
        case .urgentNotImportant:
            Color(red: 0.86, green: 0.62, blue: 0.18)
        case .notUrgentImportant:
            Color(red: 0.22, green: 0.54, blue: 0.36)
        case .notUrgentNotImportant:
            Color(red: 0.43, green: 0.45, blue: 0.48)
        }
    }

    static func normalized(from rawValue: String?) -> TaskPriority {
        guard let rawValue else { return .importantUrgent }

        if let priority = TaskPriority(rawValue: rawValue) {
            return priority
        }

        switch rawValue {
        case "urgent":
            return .importantUrgent
        case "high":
            return .notUrgentImportant
        case "normal":
            return .notUrgentNotImportant
        case "low":
            return .notUrgentNotImportant
        default:
            return .importantUrgent
        }
    }
}
