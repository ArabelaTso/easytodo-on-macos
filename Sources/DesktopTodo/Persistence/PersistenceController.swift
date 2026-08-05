import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        TodoTask.self
    ])

    @MainActor
    static func modelContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let configuration: ModelConfiguration

        if inMemory {
            configuration = ModelConfiguration(
                "DesktopTodoInMemory",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            let url = try storeURL ?? defaultStoreURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            configuration = ModelConfiguration(
                "DesktopTodo",
                schema: schema,
                url: url,
                allowsSave: true
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func defaultStoreURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return directory
            .appendingPathComponent("DesktopTodo", isDirectory: true)
            .appendingPathComponent("DesktopTodo.store")
    }
}
