import Foundation
import SwiftData

enum TaskDayMaintenance {
    @MainActor
    static func rolloverUnfinishedTasksToToday(
        in context: ModelContext,
        today: Date = .now,
        calendar: Calendar = .current
    ) throws -> Bool {
        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        let didChange = rolloverUnfinishedTasksToToday(tasks, today: today, calendar: calendar)

        if didChange {
            try context.save()
        }

        return didChange
    }

    static func rolloverUnfinishedTasksToToday(
        _ tasks: [TodoTask],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        let todayStart = calendar.startOfDay(for: today)
        var nextSortOrder = (tasks
            .filter { $0.isScheduled(on: todayStart, calendar: calendar) }
            .map(\.sortOrder)
            .max() ?? -1) + 1
        var didChange = false

        let overdueTasks = tasks
            .filter { task in
                !task.isCompleted && task.repeatRule == .none && task.scheduledDay(in: calendar) < todayStart
            }
            .sorted { lhs, rhs in
                let lhsDay = lhs.scheduledDay(in: calendar)
                let rhsDay = rhs.scheduledDay(in: calendar)

                if lhsDay != rhsDay {
                    return lhsDay < rhsDay
                }

                if lhs.sortOrder != rhs.sortOrder {
                    return lhs.sortOrder < rhs.sortOrder
                }

                return lhs.createdAt < rhs.createdAt
            }

        for task in overdueTasks {
            task.scheduledDate = todayStart
            task.sortOrder = nextSortOrder
            nextSortOrder += 1
            didChange = true
        }

        return didChange
    }
}
