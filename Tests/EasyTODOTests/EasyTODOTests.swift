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
}
