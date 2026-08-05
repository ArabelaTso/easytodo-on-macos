import SwiftUI

enum TaskPriority: String, CaseIterable, Identifiable {
    case importantUrgent
    case urgentNotImportant
    case notUrgentImportant
    case notUrgentNotImportant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .importantUrgent:
            "重要且紧急"
        case .urgentNotImportant:
            "紧急但不重要"
        case .notUrgentImportant:
            "不紧急但重要"
        case .notUrgentNotImportant:
            "不紧急也不重要"
        }
    }

    var color: Color {
        switch self {
        case .importantUrgent:
            Color.red
        case .urgentNotImportant:
            Color.orange
        case .notUrgentImportant:
            Color.blue
        case .notUrgentNotImportant:
            Color.gray
        }
    }

    var systemImage: String {
        switch self {
        case .importantUrgent:
            "flame.fill"
        case .urgentNotImportant:
            "clock.badge.exclamationmark.fill"
        case .notUrgentImportant:
            "star.circle.fill"
        case .notUrgentNotImportant:
            "circle.fill"
        }
    }

    static func normalized(from rawValue: String?) -> TaskPriority {
        guard let rawValue else { return .notUrgentNotImportant }

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
            return .notUrgentNotImportant
        }
    }
}
