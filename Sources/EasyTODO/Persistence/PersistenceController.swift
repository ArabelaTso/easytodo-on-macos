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
                "EasyTODOInMemory",
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            let url = try storeURL ?? defaultStoreURL()
            if storeURL == nil {
                try migrateLegacyStoreIfNeeded(to: url)
            }

            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            configuration = ModelConfiguration(
                "EasyTODO",
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
            .appendingPathComponent("EasyTODO", isDirectory: true)
            .appendingPathComponent("EasyTODO.store")
    }

    private static func migrateLegacyStoreIfNeeded(to storeURL: URL) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: storeURL.path) else { return }

        let applicationSupport = storeURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let legacyStoreURLs = [
            applicationSupport
                .appendingPathComponent("DesktopTodo", isDirectory: true)
                .appendingPathComponent("DesktopTodo.store"),
            applicationSupport.appendingPathComponent("default.store")
        ]

        guard let legacyStoreURL = legacyStoreURLs.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return
        }

        try fileManager.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        for suffix in ["", "-shm", "-wal"] {
            let sourceURL = URL(fileURLWithPath: legacyStoreURL.path + suffix)
            let destinationURL = URL(fileURLWithPath: storeURL.path + suffix)

            guard fileManager.fileExists(atPath: sourceURL.path),
                  !fileManager.fileExists(atPath: destinationURL.path) else {
                continue
            }

            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }
}
