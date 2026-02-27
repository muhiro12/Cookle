import Foundation
import SwiftData

public enum ModelContainerFactory {
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

    public static func sharedContext() throws -> ModelContext {
        .init(try shared())
    }
}

extension ModelContainerFactory {
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
}

private extension ModelContainerFactory {
    @MainActor
    static func objectCounts(in context: ModelContext) throws -> MigrationObjectCounts {
        try .init(
            recipeCount: count(in: context, Recipe.self),
            diaryCount: count(in: context, Diary.self),
            categoryCount: count(in: context, Category.self),
            ingredientCount: count(in: context, Ingredient.self),
            photoCount: count(in: context, Photo.self)
        )
    }

    @MainActor
    static func count<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Int {
        let fetchDescriptor: FetchDescriptor<Model> = .init()
        return try context.fetchCount(fetchDescriptor)
    }
}

struct MigrationObjectCounts: Equatable {
    let recipeCount: Int
    let diaryCount: Int
    let categoryCount: Int
    let ingredientCount: Int
    let photoCount: Int

    nonisolated func hasMatchingRecipeAndDiaryCounts(as legacyObjectCounts: Self) -> Bool {
        recipeCount == legacyObjectCounts.recipeCount
            && diaryCount == legacyObjectCounts.diaryCount
    }

    nonisolated var summary: String {
        "recipe=\(recipeCount), diary=\(diaryCount), category=\(categoryCount), ingredient=\(ingredientCount), photo=\(photoCount)"
    }
}

enum MigrationValidationError: Equatable, LocalizedError {
    case recipeAndDiaryCountMismatch(
            legacyObjectCounts: MigrationObjectCounts,
            currentObjectCounts: MigrationObjectCounts
         )

    var errorDescription: String? {
        switch self {
        case .recipeAndDiaryCountMismatch(
            let legacyObjectCounts,
            let currentObjectCounts
        ):
            return """
            Migrated store validation failed. \
            legacy[\(legacyObjectCounts.summary)] \
            current[\(currentObjectCounts.summary)]
            """
        }
    }
}
