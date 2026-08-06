import Foundation
import SwiftData

enum TaskCreation {
    @MainActor
    static func addTask(
        title: String,
        scheduledDate: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current
    ) throws -> TodoTask? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        let dayTasks = tasks.filter { task in
            task.isScheduled(on: scheduledDate, calendar: calendar)
        }
        let nextSortOrder = (dayTasks.map(\.sortOrder).max() ?? -1) + 1
        let task = TodoTask(title: trimmedTitle, sortOrder: nextSortOrder, scheduledDate: scheduledDate)

        context.insert(task)
        try context.save()

        return task
    }
}
