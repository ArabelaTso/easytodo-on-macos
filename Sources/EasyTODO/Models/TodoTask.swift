import Foundation
import SwiftData

@Model
final class TodoTask {
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    var priorityRawValue: String?

    init(
        title: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        priority: TaskPriority = .notUrgentImportant
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.priorityRawValue = priority.rawValue
    }

    var priority: TaskPriority {
        get {
            TaskPriority.normalized(from: priorityRawValue)
        }
        set {
            priorityRawValue = newValue.rawValue
        }
    }
}
