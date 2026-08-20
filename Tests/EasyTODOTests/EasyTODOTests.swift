import SwiftData
import XCTest
@testable import EasyTODO

@MainActor
final class EasyTODOTests: XCTestCase {
    func testTaskDefaultsToIncomplete() {
        let task = TodoTask(title: "Read paper", sortOrder: 2)

        XCTAssertEqual(task.title, "Read paper")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.sortOrder, 2)
        XCTAssertEqual(task.priority, .notUrgentImportant)
        XCTAssertTrue(task.isScheduled(on: .now))
    }

    func testTaskScheduledDateIsStoredAsStartOfDay() throws {
        let calendar = Calendar.current
        let futureDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 12, day: 18, hour: 15)))
        let task = TodoTask(title: "Plan launch", scheduledDate: futureDate)
        let expectedDay = calendar.startOfDay(for: futureDate)

        XCTAssertEqual(task.scheduledDate, Optional(expectedDay))
        XCTAssertTrue(task.isScheduled(on: futureDate, calendar: calendar))
        XCTAssertTrue(task.isScheduled(on: expectedDay, calendar: calendar))
    }

    func testTaskCanStorePriority() {
        let task = TodoTask(title: "Finish report", priority: .importantUrgent)

        XCTAssertEqual(task.priority, .importantUrgent)

        task.priority = .notUrgentImportant

        XCTAssertEqual(task.priority, .notUrgentImportant)
    }

    func testTaskCanStoreRepeatRule() {
        let task = TodoTask(title: "Standup", repeatRule: .daily)

        XCTAssertEqual(task.repeatRule, .daily)

        task.repeatRule = .weekly

        XCTAssertEqual(task.repeatRule, .weekly)
    }

    func testLegacyPriorityValuesAreMapped() {
        XCTAssertEqual(TaskPriority.normalized(from: "urgent"), .importantUrgent)
        XCTAssertEqual(TaskPriority.normalized(from: "high"), .notUrgentImportant)
        XCTAssertEqual(TaskPriority.normalized(from: "normal"), .notUrgentNotImportant)
        XCTAssertEqual(TaskPriority.normalized(from: nil), .notUrgentImportant)
    }

    func testInMemoryContainerPersistsInsertedTask() throws {
        let container = try PersistenceController.modelContainer(inMemory: true)
        let context = container.mainContext
        let task = TodoTask(title: "Reply email", sortOrder: 0)

        context.insert(task)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Reply email")
    }

    func testCanAddMultipleTasksInARow() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let container = try PersistenceController.modelContainer(inMemory: true)
        let context = container.mainContext

        let first = try TaskCreation.addTask(title: "First task", scheduledDate: today, in: context, calendar: calendar)
        let second = try TaskCreation.addTask(title: "Second task", scheduledDate: today, in: context, calendar: calendar)
        let third = try TaskCreation.addTask(title: "Third task", scheduledDate: today, in: context, calendar: calendar)

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        let todayTasks = TaskListOrdering.ordered(tasks.filter { $0.isScheduled(on: today, calendar: calendar) })

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertNotNil(third)
        XCTAssertEqual(todayTasks.map(\.title), ["First task", "Second task", "Third task"])
        XCTAssertEqual(todayTasks.map(\.sortOrder), [0, 1, 2])
    }

    func testBlankTaskTitleDoesNotInterruptLaterAdds() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let container = try PersistenceController.modelContainer(inMemory: true)
        let context = container.mainContext

        let blank = try TaskCreation.addTask(title: "   ", scheduledDate: today, in: context, calendar: calendar)
        let task = try TaskCreation.addTask(title: "Valid task", scheduledDate: today, in: context, calendar: calendar)
        let tasks = try context.fetch(FetchDescriptor<TodoTask>())

        XCTAssertNil(blank)
        XCTAssertNotNil(task)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Valid task")
        XCTAssertEqual(tasks.first?.sortOrder, 0)
    }

    func testTasksAreOrderedByPriorityThenAddOrder() {
        let firstGreen = TodoTask(title: "First green", sortOrder: 0, priority: .notUrgentImportant)
        let red = TodoTask(title: "Red", sortOrder: 1, priority: .importantUrgent)
        let yellow = TodoTask(title: "Yellow", sortOrder: 2, priority: .urgentNotImportant)
        let secondGreen = TodoTask(title: "Second green", sortOrder: 3, priority: .notUrgentImportant)

        XCTAssertEqual(
            TaskListOrdering.ordered([firstGreen, red, yellow, secondGreen]).map(\.title),
            ["Red", "Yellow", "First green", "Second green"]
        )
    }

    func testTaskCanMoveToAnotherDate() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let tomorrow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 6, hour: 9)))
        let existingTomorrowTask = TodoTask(title: "Tomorrow first", sortOrder: 0, scheduledDate: tomorrow)
        let task = TodoTask(title: "Move me", sortOrder: 0, scheduledDate: today)

        TaskScheduling.move(task, to: tomorrow, among: [existingTomorrowTask, task], calendar: calendar)

        XCTAssertTrue(task.isScheduled(on: tomorrow, calendar: calendar))
        XCTAssertEqual(task.sortOrder, 1)
    }

    func testDailyRepeatCreatesUpcomingOccurrences() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let container = try PersistenceController.modelContainer(inMemory: true)
        let context = container.mainContext
        let task = TodoTask(title: "Drink water", sortOrder: 0, scheduledDate: today)
        context.insert(task)

        try TaskRepeatScheduler.setRepeatRule(.daily, for: task, tasks: [task], in: context, calendar: calendar)

        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))

        XCTAssertEqual(task.repeatRule, .daily)
        XCTAssertEqual(tasks.filter { $0.isScheduled(on: tomorrow, calendar: calendar) }.count, 1)
    }

    func testNewlyCompletedTaskMovesToFrontOfCompletedTasks() {
        let first = TodoTask(title: "Read paper", sortOrder: 0)
        let second = TodoTask(title: "Reply email", sortOrder: 1)
        let third = TodoTask(title: "Finish report", sortOrder: 2)
        let tasks = [first, second, third]

        second.isCompleted = true
        TaskListOrdering.moveCompletedTaskToFront(second, in: tasks)

        third.isCompleted = true
        TaskListOrdering.moveCompletedTaskToFront(third, in: tasks)

        XCTAssertEqual(
            TaskListOrdering.ordered(tasks).map(\.title),
            ["Read paper", "Finish report", "Reply email"]
        )
    }

    func testPersistentContainerReopensSavedTask() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyTODOTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = directory.appendingPathComponent("EasyTODO.store")

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        do {
            let container = try PersistenceController.modelContainer(storeURL: storeURL)
            let context = container.mainContext
            context.insert(TodoTask(title: "Persist me", sortOrder: 0))
            try context.save()
        }

        do {
            let container = try PersistenceController.modelContainer(storeURL: storeURL)
            let tasks = try container.mainContext.fetch(FetchDescriptor<TodoTask>())

            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.title, "Persist me")
        }
    }

    func testPersistentContainerReopensSavedFutureTaskDate() throws {
        let calendar = Calendar.current
        let futureDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2027, month: 1, day: 9, hour: 9)))
        let expectedDay = calendar.startOfDay(for: futureDate)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EasyTODOTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = directory.appendingPathComponent("EasyTODO.store")

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        do {
            let container = try PersistenceController.modelContainer(storeURL: storeURL)
            let context = container.mainContext
            context.insert(TodoTask(title: "Future task", sortOrder: 0, scheduledDate: futureDate))
            try context.save()
        }

        do {
            let container = try PersistenceController.modelContainer(storeURL: storeURL)
            let tasks = try container.mainContext.fetch(FetchDescriptor<TodoTask>())

            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.scheduledDate, Optional(expectedDay))
            XCTAssertTrue(try XCTUnwrap(tasks.first).isScheduled(on: futureDate, calendar: calendar))
        }
    }

    func testUnfinishedPastTasksRollOverToToday() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let yesterday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 4, hour: 9)))
        let todayTask = TodoTask(title: "Already today", sortOrder: 2, scheduledDate: today)
        let overdueTask = TodoTask(title: "Carry forward", sortOrder: 0, scheduledDate: yesterday)
        let completedPastTask = TodoTask(title: "Done yesterday", isCompleted: true, sortOrder: 1, scheduledDate: yesterday)

        let didChange = TaskDayMaintenance.rolloverUnfinishedTasksToToday(
            [todayTask, overdueTask, completedPastTask],
            today: today,
            calendar: calendar
        )

        XCTAssertTrue(didChange)
        XCTAssertTrue(overdueTask.isScheduled(on: today, calendar: calendar))
        XCTAssertEqual(overdueTask.sortOrder, 3)
        XCTAssertTrue(completedPastTask.isScheduled(on: yesterday, calendar: calendar))
    }

    func testTodayAndFutureTasksDoNotRollOver() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: 9)))
        let tomorrow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 6, hour: 9)))
        let todayTask = TodoTask(title: "Today", scheduledDate: today)
        let futureTask = TodoTask(title: "Future", scheduledDate: tomorrow)

        let didChange = TaskDayMaintenance.rolloverUnfinishedTasksToToday(
            [todayTask, futureTask],
            today: today,
            calendar: calendar
        )

        XCTAssertFalse(didChange)
        XCTAssertTrue(todayTask.isScheduled(on: today, calendar: calendar))
        XCTAssertTrue(futureTask.isScheduled(on: tomorrow, calendar: calendar))
    }
}
