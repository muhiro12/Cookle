import Foundation
import MHPlatformCore

/// Migrates persisted store files between legacy and current locations.
public enum DatabaseMigrator {
    /// Reasons why store migration or cleanup was skipped.
    public enum MigrationSkipReason {
        /// The legacy and current store URLs already point to the same location.
        case sameLocation
        /// The legacy store file does not exist.
        case missingLegacyStore
        /// The current store file does not exist.
        case missingCurrentStore
    }

    /// Outcome produced when copying legacy store files into the current location.
    public enum MigrationOutcome {
        /// Legacy files were copied into the current store location.
        case migrated(
                copiedFileNames: [String],
                removedCurrentFileNames: [String]
             )
        /// Migration was skipped for a safe, known reason.
        case skipped(MigrationSkipReason)
    }

    /// Outcome produced when deleting legacy store files after migration.
    public enum LegacyCleanupOutcome {
        /// Legacy files were removed after the current store was confirmed.
        case removed(fileNames: [String])
        /// Cleanup was skipped for a safe, known reason.
        case skipped(MigrationSkipReason)
    }

    /// Copies legacy store files into the current location when required.
    @discardableResult
    public static func migrateStoreFilesIfNeeded() throws -> MigrationOutcome {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    /// Removes legacy store files after a successful migration.
    @discardableResult
    public static func removeLegacyStoreFilesIfNeeded() throws -> LegacyCleanupOutcome {
        try removeLegacyStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    @discardableResult
    static func migrateStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        validateMigration: @Sendable (
            _ currentStoreURL: URL,
            _ copiedFileNames: [String]
        ) throws -> Void = { _, _ in
            // Intentionally empty.
        }
    ) throws -> MigrationOutcome {
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL else {
            return .skipped(.sameLocation)
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return .skipped(.missingLegacyStore)
        }

        let plan = MHStoreRelocationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        let outcome = try MHStoreRelocationService.relocateIfNeeded(
            plan: plan,
            fileManager: fileManager,
            validateRelocatedStore: validateMigration
        )
        return .init(outcome)
    }

    @discardableResult
    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws -> LegacyCleanupOutcome {
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL else {
            return .skipped(.sameLocation)
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return .skipped(.missingLegacyStore)
        }
        guard fileManager.fileExists(atPath: currentURL.path) else {
            return .skipped(.missingCurrentStore)
        }

        let plan = MHStoreRelocationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        let outcome = try MHStoreRelocationService.removeLegacyStoreFilesIfNeeded(
            plan: plan,
            fileManager: fileManager
        )
        return .init(outcome)
    }
}

private extension DatabaseMigrator.MigrationOutcome {
    init(_ outcome: MHStoreRelocationOutcome) {
        switch outcome {
        case let .relocated(
            copiedFileNames: copiedFileNames,
            removedCurrentFileNames: removedCurrentFileNames
        ):
            self = .migrated(
                copiedFileNames: copiedFileNames,
                removedCurrentFileNames: removedCurrentFileNames
            )
        case .skipped(let reason):
            self = .skipped(.init(reason))
        }
    }
}

private extension DatabaseMigrator.LegacyCleanupOutcome {
    init(_ outcome: MHLegacyStoreCleanupOutcome) {
        switch outcome {
        case .removed(let fileNames):
            self = .removed(fileNames: fileNames)
        case .skipped(let reason):
            self = .skipped(.init(reason))
        }
    }
}

private extension DatabaseMigrator.MigrationSkipReason {
    init(_ reason: MHStoreRelocationSkipReason) {
        switch reason {
        case .sameLocation:
            self = .sameLocation
        case .missingLegacyStore:
            self = .missingLegacyStore
        }
    }
}
