import Foundation
import MHPlatformCore
import SwiftData

/// Builds model containers and contexts used by Cookle.
public enum ModelContainerFactory {
    private enum MeasurementConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
    }

    /// Returns the shared model container configuration.
    public static func shared() throws -> ModelContainer {
        try makeModelContainer()
    }

    /// Creates the model container used by the main app and validates migrated data.
    @preconcurrency
    public static func appContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        logger: MHLogger? = nil
    ) throws -> ModelContainer {
        let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
        let migrationOutcome = try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        ) { currentStoreURL, _ in
            try validateMigratedDataBeforeDeletingLegacyIfNeeded(
                currentStoreURL: currentStoreURL,
                cloudKitDatabase: cloudKitDatabase,
                legacyURL: Database.legacyURL,
                logger: logger
            )
        }
        logMigrationOutcome(
            migrationOutcome,
            logger: logger
        )
        let currentContainer = try makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        let cleanupOutcome = try DatabaseMigrator.removeLegacyStoreFilesIfNeeded()
        logCleanupOutcome(
            cleanupOutcome,
            logger: logger
        )
        logger?.notice(
            "store prep finished",
            metadata: [
                "duration_ms": durationMilliseconds(
                    since: storePreparationStartedAt
                ).description
            ]
        )
        return currentContainer
    }

    /// Returns a `ModelContext` backed by the shared container.
    public static func sharedContext() throws -> ModelContext {
        .init(try shared())
    }

    static func makeModelContainer(
        url: URL? = nil,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
    ) throws -> ModelContainer {
        if let url {
            return try ModelContainer(
                for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
                migrationPlan: CookleMigrationPlan.self,
                configurations: .init(
                    url: url,
                    cloudKitDatabase: cloudKitDatabase
                )
            )
        }
        return try ModelContainer(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                cloudKitDatabase: cloudKitDatabase
            )
        )
    }

    static func validateMigratedDataBeforeDeletingLegacyIfNeeded(
        currentStoreURL: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        legacyURL: URL = Database.legacyURL,
        fileManager: FileManager = .default,
        logger: MHLogger? = nil
    ) throws {
        let validationStartedAt = Date.timeIntervalSinceReferenceDate
        guard legacyURL.standardizedFileURL != currentStoreURL.standardizedFileURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        do {
            _ = try makeModelContainer(
                url: currentStoreURL,
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            logger?.error(
                "store migration validation failed",
                metadata: [
                    "error_type": String(describing: type(of: error)),
                    "error": error.localizedDescription
                ]
            )
            throw error
        }
        logger?.notice(
            "store migration validation finished",
            metadata: [
                "duration_ms": durationMilliseconds(
                    since: validationStartedAt
                ).description
            ]
        )
    }

    private static func durationMilliseconds(
        since startedAt: TimeInterval
    ) -> Int {
        Int(
            (
                Date.timeIntervalSinceReferenceDate
                    - startedAt
            ) * MeasurementConstants.millisecondsPerSecond
        )
    }

    private static func logMigrationOutcome(
        _ outcome: DatabaseMigrator.MigrationOutcome,
        logger: MHLogger?
    ) {
        guard let logger else {
            return
        }

        switch outcome {
        case let .migrated(
            copiedFileNames: copiedFileNames,
            removedCurrentFileNames: removedCurrentFileNames
        ):
            logger.notice(
                "store migration copied legacy files",
                metadata: [
                    "migration_outcome": "migrated",
                    "copied_file_names": copiedFileNames.joined(separator: "|"),
                    "removed_current_file_names": removedCurrentFileNames.joined(separator: "|")
                ]
            )
        case .skipped(let reason):
            logger.notice(
                "store migration skipped",
                metadata: [
                    "migration_outcome": "skipped",
                    "skip_reason": skipReasonValue(reason)
                ]
            )
        }
    }

    private static func logCleanupOutcome(
        _ outcome: DatabaseMigrator.LegacyCleanupOutcome,
        logger: MHLogger?
    ) {
        guard let logger else {
            return
        }

        switch outcome {
        case .removed(let fileNames):
            logger.notice(
                "legacy store cleanup removed files",
                metadata: [
                    "cleanup_outcome": "removed",
                    "removed_file_names": fileNames.joined(separator: "|")
                ]
            )
        case .skipped(let reason):
            logger.notice(
                "legacy store cleanup skipped",
                metadata: [
                    "cleanup_outcome": "skipped",
                    "skip_reason": skipReasonValue(reason)
                ]
            )
        }
    }

    private static func skipReasonValue(
        _ reason: DatabaseMigrator.MigrationSkipReason
    ) -> String {
        switch reason {
        case .sameLocation:
            "same_location"
        case .missingLegacyStore:
            "missing_legacy_store"
        case .missingCurrentStore:
            "missing_current_store"
        }
    }
}
