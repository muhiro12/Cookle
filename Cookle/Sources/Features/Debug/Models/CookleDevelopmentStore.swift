#if DEBUG
import Foundation
import SwiftData

@MainActor
enum CookleDevelopmentStore {
    // Set false before creating a fresh development store to inspect empty states.
    static let automaticallyInsertsSamples = true

    static var storeURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "CookleDevelopment", directoryHint: .isDirectory)
            .appending(path: "default.store")
    }

    static func open(
        at storeURL: URL = storeURL,
        automaticallyInsertsSamples: Bool = automaticallyInsertsSamples
    ) throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let isFirstCreation = !FileManager.default.fileExists(atPath: storeURL.path)
        let container = try ModelContainer(
            for: .init(versionedSchema: CookleMigrationPlan.currentSchema),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(url: storeURL, cloudKitDatabase: .none)
        )
        // A deliberately emptied or previously initialized store is never seeded on reopen.
        if isFirstCreation, automaticallyInsertsSamples {
            try insertSamples(context: container.mainContext, storeURL: storeURL)
        }
        return container
    }

    static func allowsMutations(_ container: ModelContainer) -> Bool {
        DevelopmentSampleOperations.allowsMutations(container: container, storeURL: storeURL)
    }

    static func requireMutationAccess(_ container: ModelContainer) throws {
        guard allowsMutations(container) else {
            throw DevelopmentSampleOperations.SampleError.unsafeStore
        }
    }

    static func insertSamples(context: ModelContext) throws {
        try insertSamples(context: context, storeURL: storeURL)
    }

    private static func insertSamples(context: ModelContext, storeURL: URL) throws {
        try DevelopmentSampleOperations.insert(context: context, storeURL: storeURL) { context in
            // Reuse the existing fixtures offline; captures retain their own photo-loading path.
            try CooklePreviewStore().prepare(context)
        }
    }
}
#endif
