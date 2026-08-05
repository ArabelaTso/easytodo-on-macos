import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        TodoTask.self
    ])

    @MainActor
    static func modelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
