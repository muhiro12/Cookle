import Foundation
import SwiftData

/// Builds model containers and contexts used by Cookle.
public enum ModelContainerFactory {
    /// Returns the shared model container configuration.
    public static func shared() throws -> ModelContainer {
        try makeModelContainer()
    }

    /// Creates the model container used by the main app and validates migrated data.
    @preconcurrency
    @MainActor
    public static func appContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        try DatabaseMigrator.migrateStoreFilesIfNeeded()
        let currentContainer = try makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        try validateMigratedDataBeforeDeletingLegacyIfNeeded(
            currentContainer: currentContainer,
            cloudKitDatabase: cloudKitDatabase
        )
        try DatabaseMigrator.removeLegacyStoreFilesIfNeeded()
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

    @MainActor
    static func validateMigratedDataBeforeDeletingLegacyIfNeeded(
        currentContainer: ModelContainer,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        legacyURL: URL = Database.legacyURL,
        currentURL: URL = Database.url,
        fileManager: FileManager = .default
    ) throws {
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
        let legacyObjectCounts = try objectCounts(in: legacyContainer.mainContext)
        let currentObjectCounts = try objectCounts(in: currentContainer.mainContext)
        guard currentObjectCounts.hasMatchingRecipeAndDiaryCounts(
            as: legacyObjectCounts
        ) else {
            throw MigrationValidationError.recipeAndDiaryCountMismatch(
                legacyObjectCounts: legacyObjectCounts,
                currentObjectCounts: currentObjectCounts
            )
        }
    }

    @MainActor
    private static func objectCounts(in context: ModelContext) throws -> MigrationObjectCounts {
        try .init(
            recipeCount: count(in: context, Recipe.self),
            diaryCount: count(in: context, Diary.self),
            categoryCount: count(in: context, Category.self),
            ingredientCount: count(in: context, Ingredient.self),
            photoCount: count(in: context, Photo.self)
        )
    }

    @MainActor
    private static func count<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Int {
        let fetchDescriptor: FetchDescriptor<Model> = .init()
        return try context.fetchCount(fetchDescriptor)
    }
}
