import Foundation
import MHPlatformCore
import SwiftData

extension ModelContainerFactory {
    struct StoreValidationSnapshotContext {
        let currentContainer: ModelContainer
        let legacyURL: URL
        let currentStoreURL: URL
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase
        let fileManager: FileManager
        let validationStartedAt: TimeInterval
    }
}

private extension ModelContainerFactory {
    struct StoreFileSnapshot: Equatable {
        let exists: Bool
        let fileNames: [String]

        var fileNamesSummary: String {
            guard fileNames.isEmpty == false else {
                return "none"
            }

            return fileNames.joined(separator: "|")
        }
    }

    struct StoreEntityCounts: Equatable {
        let recipeCount: Int
        let diaryCount: Int
        let categoryCount: Int
        let ingredientCount: Int
        let photoCount: Int

        var summary: String {
            [
                "recipe=\(recipeCount)",
                "diary=\(diaryCount)",
                "category=\(categoryCount)",
                "ingredient=\(ingredientCount)",
                "photo=\(photoCount)"
            ]
            .joined(separator: "|")
        }
    }

    static func countSummary(
        in context: ModelContext
    ) throws -> StoreEntityCounts {
        try .init(
            recipeCount: count(in: context, Recipe.self),
            diaryCount: count(in: context, Diary.self),
            categoryCount: count(in: context, Category.self),
            ingredientCount: count(in: context, Ingredient.self),
            photoCount: count(in: context, Photo.self)
        )
    }

    static func count<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Int {
        let fetchDescriptor: FetchDescriptor<Model> = .init()
        return try context.fetchCount(fetchDescriptor)
    }
}

extension ModelContainerFactory {
    static func prepareStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        logger: MHLogger?
    ) throws -> DatabaseMigrator.MigrationOutcome {
        logRelocationPlanIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            cloudKitDatabase: cloudKitDatabase,
            logger: logger
        )

        return try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        ) { currentStoreURL, _ in
            try validateMigratedDataBeforeDeletingLegacyIfNeeded(
                currentStoreURL: currentStoreURL,
                cloudKitDatabase: cloudKitDatabase,
                legacyURL: legacyURL,
                fileManager: .default,
                logger: logger
            )
        }
    }

    static func cleanupLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws -> DatabaseMigrator.LegacyCleanupOutcome {
        try DatabaseMigrator.removeLegacyStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )
    }

    static func logMigrationOutcome(
        _ outcome: DatabaseMigrator.MigrationOutcome,
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
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
            var metadata = storeStateMetadata(
                fileManager: fileManager,
                legacyURL: legacyURL,
                currentURL: currentURL
            )
            metadata["migration_outcome"] = "migrated"
            metadata["copied_file_names"] = copiedFileNames.joined(separator: "|")
            metadata["removed_current_file_names"] = removedCurrentFileNames.joined(separator: "|")
            logger.warning(
                "store migration copied legacy files",
                metadata: metadata
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

    static func logCleanupOutcome(
        _ outcome: DatabaseMigrator.LegacyCleanupOutcome,
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        logger: MHLogger?
    ) {
        guard let logger else {
            return
        }

        switch outcome {
        case .removed(let fileNames):
            var metadata = storeStateMetadata(
                fileManager: fileManager,
                legacyURL: legacyURL,
                currentURL: currentURL
            )
            metadata["cleanup_outcome"] = "removed"
            metadata["removed_file_names"] = fileNames.joined(separator: "|")
            logger.warning(
                "legacy store cleanup removed files",
                metadata: metadata
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

    static func logValidationSnapshot(
        _ context: StoreValidationSnapshotContext,
        logger: MHLogger?
    ) {
        guard let logger else {
            return
        }

        var metadata = storeStateMetadata(
            fileManager: context.fileManager,
            legacyURL: context.legacyURL,
            currentURL: context.currentStoreURL
        )
        metadata["cloudkit_database"] = String(
            describing: context.cloudKitDatabase
        )
        metadata["duration_ms"] = durationMilliseconds(
            since: context.validationStartedAt
        ).description

        let currentCounts = attachCurrentCounts(
            to: &metadata,
            currentContainer: context.currentContainer
        )
        attachLegacyCounts(
            to: &metadata,
            legacyURL: context.legacyURL,
            cloudKitDatabase: context.cloudKitDatabase,
            currentCounts: currentCounts
        )

        logger.warning(
            validationSnapshotMessage(metadata: metadata),
            metadata: metadata
        )
    }

    static func storeStateMetadata(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) -> [String: String] {
        storeMetadata(
            prefix: "legacy",
            url: legacyURL,
            snapshot: storeSnapshot(
                fileManager: fileManager,
                storeURL: legacyURL
            )
        )
        .merging(
            storeMetadata(
                prefix: "current",
                url: currentURL,
                snapshot: storeSnapshot(
                    fileManager: fileManager,
                    storeURL: currentURL
                )
            )
        ) { _, newValue in
            newValue
        }
    }

    private static func attachCurrentCounts(
        to metadata: inout [String: String],
        currentContainer: ModelContainer
    ) -> StoreEntityCounts? {
        do {
            let currentCounts = try countSummary(
                in: .init(currentContainer)
            )
            metadata["current_counts"] = currentCounts.summary
            return currentCounts
        } catch {
            metadata["current_counts_error_type"] = String(
                describing: type(of: error)
            )
            metadata["current_counts_error"] = error.localizedDescription
            return nil
        }
    }
}

private extension ModelContainerFactory {
    static func attachLegacyCounts(
        to metadata: inout [String: String],
        legacyURL: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        currentCounts: StoreEntityCounts?
    ) {
        do {
            let legacyContainer = try makeModelContainer(
                url: legacyURL,
                cloudKitDatabase: cloudKitDatabase
            )
            let legacyCounts = try countSummary(
                in: .init(legacyContainer)
            )
            metadata["legacy_counts"] = legacyCounts.summary
            if let currentCounts {
                metadata["counts_match"] = (currentCounts == legacyCounts).description
            }
        } catch {
            metadata["legacy_counts_error_type"] = String(
                describing: type(of: error)
            )
            metadata["legacy_counts_error"] = error.localizedDescription
        }
    }

    static func validationSnapshotMessage(
        metadata: [String: String]
    ) -> String {
        if metadata["counts_match"] == true.description {
            return "store migration validation snapshot"
        }
        if metadata["counts_match"] == false.description {
            return "store migration validation counts changed"
        }
        return "store migration validation snapshot"
    }

    static func logRelocationPlanIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        logger: MHLogger?
    ) {
        guard let logger else {
            return
        }
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        var metadata = storeStateMetadata(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )
        metadata["cloudkit_database"] = String(
            describing: cloudKitDatabase
        )
        logger.warning(
            "store migration requires relocation",
            metadata: metadata
        )
    }

    static func skipReasonValue(
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

    static func storeMetadata(
        prefix: String,
        url: URL,
        snapshot: StoreFileSnapshot
    ) -> [String: String] {
        [
            "\(prefix)_store_url": url.standardizedFileURL.path,
            "\(prefix)_store_exists": snapshot.exists.description,
            "\(prefix)_store_file_count": snapshot.fileNames.count.description,
            "\(prefix)_store_files": snapshot.fileNamesSummary
        ]
    }

    static func storeSnapshot(
        fileManager: FileManager,
        storeURL: URL
    ) -> StoreFileSnapshot {
        let directoryURL = storeURL.deletingLastPathComponent()
        let baseName = storeURL.lastPathComponent
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return .init(
                exists: false,
                fileNames: []
            )
        }

        let fileNames = (try? fileManager.contentsOfDirectory(
            atPath: directoryURL.path
        ))?
        .filter { fileName in
            fileName == baseName || fileName.hasPrefix(baseName + "-")
        }
        .sorted() ?? []

        return .init(
            exists: fileNames.isEmpty == false,
            fileNames: fileNames
        )
    }
}
