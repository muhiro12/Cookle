import Foundation
import SwiftData

extension ModelContainerFactory {
    static func protectPopulatedDestination(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL,
              fileManager.fileExists(atPath: legacyURL.path),
              fileManager.fileExists(atPath: currentURL.path) else {
            return
        }
        // Older widgets could create an empty destination before the app relocated.
        // Only replace a proven-empty store; preserve both copies on conflict or error.
        let container = try makeReadOnlyContainer(url: currentURL)
        let context = ModelContext(container)
        for model in CookleMigrationPlan.currentSchema.models
        where try containsRecords(model, context: context) {
            throw CocoaError(.fileWriteFileExists)
        }
    }

    private static func containsRecords<Model: PersistentModel>(
        _: Model.Type,
        context: ModelContext
    ) throws -> Bool {
        var descriptor = FetchDescriptor<Model>()
        descriptor.fetchLimit = 1
        return try context.fetchCount(descriptor) > .zero
    }
}
