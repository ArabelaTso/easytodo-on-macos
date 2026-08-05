import SwiftData
import XCTest
@testable import DesktopTodo

@MainActor
final class DesktopTodoTests: XCTestCase {
    func testTaskDefaultsToIncomplete() {
        let task = TodoTask(title: "Read paper", sortOrder: 2)

        XCTAssertEqual(task.title, "Read paper")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.sortOrder, 2)
        XCTAssertEqual(task.priority, .notUrgentNotImportant)
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
}
