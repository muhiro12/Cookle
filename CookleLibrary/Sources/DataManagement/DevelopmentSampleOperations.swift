#if DEBUG
import Foundation
import SwiftData

/// Guarded fixture insertion for an explicitly separate, unsynced development store.
@preconcurrency
@MainActor
public enum DevelopmentSampleOperations {
    public enum SampleError: LocalizedError {
        case unsafeStore
        case pendingChanges
        case nonemptyStore

        public var errorDescription: String? {
            switch self {
            case .unsafeStore:
                "Samples require the separate local development store."
            case .pendingChanges:
                "Finish pending edits before adding samples."
            case .nonemptyStore:
                "Samples can only be added to an empty development store."
            }
        }
    }

    /// Rejects user, shared, in-memory, read-only, and CloudKit-backed configurations.
    public static func allowsMutations(container: ModelContainer, storeURL: URL) -> Bool {
        allowsMutations(configurations: Array(container.configurations), storeURL: storeURL)
    }

    static func allowsMutations(configurations: [ModelConfiguration], storeURL: URL) -> Bool {
        let expectedURL = storeURL.resolvingSymlinksInPath().standardizedFileURL
        guard expectedURL != Database.url.resolvingSymlinksInPath().standardizedFileURL,
              expectedURL != Database.legacyURL.resolvingSymlinksInPath().standardizedFileURL,
              configurations.count == 1,
              let configuration = configurations.first else {
            return false
        }
        return configuration.url.resolvingSymlinksInPath().standardizedFileURL == expectedURL
            && !configuration.isStoredInMemoryOnly
            && configuration.allowsSave
            && configuration.cloudKitContainerIdentifier == nil
    }

    /// The fixture closure must not save. This boundary owns the single commit and rollback.
    public static func insert(
        context: ModelContext,
        storeURL: URL,
        create: (ModelContext) throws -> Void
    ) throws {
        guard allowsMutations(container: context.container, storeURL: storeURL) else {
            throw SampleError.unsafeStore
        }
        guard !context.hasChanges else {
            throw SampleError.pendingChanges
        }
        guard try DiagnosticRecordCounts.read(container: context.container).isEmpty else {
            throw SampleError.nonemptyStore
        }
        let wasAutosaveEnabled = context.autosaveEnabled
        context.autosaveEnabled = false
        defer {
            context.autosaveEnabled = wasAutosaveEnabled
        }
        do {
            try create(context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
#endif
