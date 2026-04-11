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
            let currentContainer = try makeModelContainer(
                url: currentStoreURL,
                cloudKitDatabase: cloudKitDatabase
            )
            try validateMigratedDataBeforeDeletingLegacyIfNeeded(
                currentContainer: currentContainer,
                cloudKitDatabase: cloudKitDatabase,
                legacyURL: Database.legacyURL,
                currentURL: currentStoreURL,
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
        currentContainer: ModelContainer,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        legacyURL: URL = Database.legacyURL,
        currentURL: URL = Database.url,
        fileManager: FileManager = .default,
        logger: MHLogger? = nil
    ) throws {
        let validationStartedAt = Date.timeIntervalSinceReferenceDate
        guard legacyURL != currentURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        let legacyContainer = try makeModelContainer(
            url: legacyURL,
            cloudKitDatabase: cloudKitDatabase
        )
        let legacyObjectCounts = try objectCounts(
            in: .init(legacyContainer)
        )
        let currentObjectCounts = try objectCounts(
            in: .init(currentContainer)
        )
        guard currentObjectCounts.hasMatchingPersistedEntityCounts(
            as: legacyObjectCounts
        ) else {
            logger?.error(
                "store migration validation failed",
                metadata: [
                    "legacy_counts": legacyObjectCounts.summary,
                    "current_counts": currentObjectCounts.summary
                ]
            )
            throw MigrationValidationError.persistedEntityCountMismatch(
                legacyObjectCounts: legacyObjectCounts,
                currentObjectCounts: currentObjectCounts
            )
        }
        logger?.notice(
            "store migration validation finished",
            metadata: [
                "duration_ms": durationMilliseconds(
                    since: validationStartedAt
                ).description,
                "legacy_counts": legacyObjectCounts.summary,
                "current_counts": currentObjectCounts.summary
            ]
        )
    }

    private static func objectCounts(in context: ModelContext) throws -> MigrationObjectCounts {
        try .init(
            recipeCount: count(in: context, Recipe.self),
            diaryCount: count(in: context, Diary.self),
            categoryCount: count(in: context, Category.self),
            ingredientCount: count(in: context, Ingredient.self),
            photoCount: count(in: context, Photo.self)
        )
    }

    private static func count<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Int {
        let fetchDescriptor: FetchDescriptor<Model> = .init()
        return try context.fetchCount(fetchDescriptor)
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
