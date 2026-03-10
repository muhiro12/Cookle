import Foundation
import OSLog
import SwiftData

/// Builds model containers and contexts used by Cookle.
public enum ModelContainerFactory {
    private enum MeasurementConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
    }

    private static let logger = Logger(
        subsystem: "CookleLibrary",
        category: "ModelContainerFactory"
    )

    /// Returns the shared model container configuration.
    public static func shared() throws -> ModelContainer {
        try makeModelContainer()
    }

    /// Creates the model container used by the main app and validates migrated data.
    @preconcurrency
    public static func appContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
        try DatabaseMigrator.migrateStoreFilesIfNeeded()
        let currentContainer = try makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        try validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentContainer: currentContainer,
            cloudKitDatabase: cloudKitDatabase
        )
        try DatabaseMigrator.removeLegacyStoreFilesIfNeeded()
        logger.notice(
            "store prep finished in \(durationMilliseconds(since: storePreparationStartedAt)) ms"
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
        fileManager: FileManager = .default
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
        guard currentObjectCounts.hasMatchingRecipeAndDiaryCounts(
            as: legacyObjectCounts
        ) else {
            throw MigrationValidationError.recipeAndDiaryCountMismatch(
                legacyObjectCounts: legacyObjectCounts,
                currentObjectCounts: currentObjectCounts
            )
        }
        logger.notice(
            "migration validation finished in \(durationMilliseconds(since: validationStartedAt)) ms"
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
}
