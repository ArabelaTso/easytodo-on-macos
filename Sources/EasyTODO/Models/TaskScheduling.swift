import Foundation
import SwiftData

enum TaskScheduling {
    static func move(_ task: TodoTask, to date: Date, among tasks: [TodoTask], calendar: Calendar = .current) {
        let targetDay = calendar.startOfDay(for: date)
        let dayTasks = tasks.filter { candidate in
            candidate !== task && candidate.isScheduled(on: targetDay, calendar: calendar)
        }

        task.scheduledDate = targetDay
        task.sortOrder = (dayTasks.map(\.sortOrder).max() ?? -1) + 1
    }
}

enum TaskRepeatScheduler {
    static let dailyHorizonDays = 30
    static let weeklyHorizonWeeks = 12

    @MainActor
    static func setRepeatRule(
        _ repeatRule: TaskRepeatRule,
        for task: TodoTask,
        tasks: [TodoTask],
        in context: ModelContext,
        calendar: Calendar = .current
    ) throws {
        task.repeatRule = repeatRule

        guard repeatRule != .none else {
            try context.save()
            return
        }

        let groupID = task.recurrenceGroupID ?? UUID().uuidString
        task.recurrenceGroupID = groupID

        for date in occurrenceDates(for: repeatRule, after: task.scheduledDay(in: calendar), calendar: calendar) {
            guard !hasOccurrence(on: date, groupID: groupID, in: tasks + [task], calendar: calendar) else {
                continue
            }

            let occurrence = TodoTask(
                title: task.title,
                sortOrder: nextSortOrder(on: date, in: tasks, calendar: calendar),
                createdAt: Date(),
                scheduledDate: date,
                priority: task.priority,
                repeatRule: repeatRule,
                recurrenceGroupID: groupID
            )
            context.insert(occurrence)
        }

        try context.save()
    }

    private static func occurrenceDates(for repeatRule: TaskRepeatRule, after date: Date, calendar: Calendar) -> [Date] {
        switch repeatRule {
        case .none:
            []
        case .daily:
            (1...dailyHorizonDays).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: date).map { calendar.startOfDay(for: $0) }
            }
        case .weekly:
            (1...weeklyHorizonWeeks).compactMap { offset in
                calendar.date(byAdding: .weekOfYear, value: offset, to: date).map { calendar.startOfDay(for: $0) }
            }
        }
    }

    private static func hasOccurrence(
        on date: Date,
        groupID: String,
        in tasks: [TodoTask],
        calendar: Calendar
    ) -> Bool {
        tasks.contains { task in
            task.recurrenceGroupID == groupID && task.isScheduled(on: date, calendar: calendar)
        }
    }

    private static func nextSortOrder(on date: Date, in tasks: [TodoTask], calendar: Calendar) -> Int {
        let dayTasks = tasks.filter { task in
            task.isScheduled(on: date, calendar: calendar)
        }

        return (dayTasks.map(\.sortOrder).max() ?? -1) + 1
    }
}
