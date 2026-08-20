import Foundation
import SwiftData

@Model
final class TodoTask {
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    var scheduledDate: Date?
    var priorityRawValue: String?
    var repeatRuleRawValue: String?
    var recurrenceGroupID: String?

    init(
        title: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        scheduledDate: Date = .now,
        priority: TaskPriority = .notUrgentImportant,
        repeatRule: TaskRepeatRule = .none,
        recurrenceGroupID: String? = nil
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.scheduledDate = Calendar.current.startOfDay(for: scheduledDate)
        self.priorityRawValue = priority.rawValue
        self.repeatRuleRawValue = repeatRule.rawValue
        self.recurrenceGroupID = recurrenceGroupID
    }

    var priority: TaskPriority {
        get {
            TaskPriority.normalized(from: priorityRawValue)
        }
        set {
            priorityRawValue = newValue.rawValue
        }
    }

    var repeatRule: TaskRepeatRule {
        get {
            TaskRepeatRule.normalized(from: repeatRuleRawValue)
        }
        set {
            repeatRuleRawValue = newValue.rawValue
        }
    }

    func scheduledDay(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: scheduledDate ?? .now)
    }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(scheduledDay(in: calendar), inSameDayAs: date)
    }
}
