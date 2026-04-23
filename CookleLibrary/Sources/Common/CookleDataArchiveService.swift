import Foundation
import SwiftData

/// Exports and restores portable Cookle backup archives.
@preconcurrency
@MainActor
public enum CookleDataArchiveService {
    public enum ArchiveError: LocalizedError, Sendable {
        case unsupportedFormatVersion(Int)
        case duplicateIdentifier(String)
        case missingReference(String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedFormatVersion(let version):
                "Unsupported backup format version: \(version)"
            case .duplicateIdentifier(let identifier):
                "Backup contains a duplicate identifier: \(identifier)"
            case .missingReference(let identifier):
                "Backup is missing referenced data: \(identifier)"
            }
        }
    }

    /// Builds an in-memory archive from the current persisted user data.
    public static func makeArchive(
        context: ModelContext
    ) throws -> CookleDataArchive {
        let ingredients = try context.fetch(.ingredients(.all))
        let categories = try context.fetch(.categories(.all))
        let photos = try context.fetch(.photos(.all))
        let recipes = try context.fetch(.recipes(.all))
        let diaries = try context.fetch(.diaries(.all))

        let ingredientIDs = identifierMap(for: ingredients, prefix: "ingredient")
        let categoryIDs = identifierMap(for: categories, prefix: "category")
        let photoIDs = identifierMap(for: photos, prefix: "photo")
        let recipeIDs = identifierMap(for: recipes, prefix: "recipe")

        return .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
            exportedAt: .now,
            ingredients: ingredientRecords(
                ingredients,
                identifiers: ingredientIDs
            ),
            categories: categoryRecords(
                categories,
                identifiers: categoryIDs
            ),
            photos: photoRecords(
                photos,
                identifiers: photoIDs
            ),
            recipes: recipeRecords(
                recipes,
                recipeIDs: recipeIDs,
                photoIDs: photoIDs,
                ingredientIDs: ingredientIDs,
                categoryIDs: categoryIDs
            ),
            diaries: diaryRecords(
                diaries,
                identifiers: identifierMap(
                    for: diaries,
                    prefix: "diary"
                ),
                recipeIDs: recipeIDs
            )
        )
    }

    /// Encodes the current persisted user data as portable JSON backup data.
    public static func encodedArchive(
        from context: ModelContext
    ) throws -> Data {
        try encoder.encode(
            makeArchive(
                context: context
            )
        )
    }

    /// Decodes JSON backup data without applying it to the store.
    public static func decodedArchive(
        from data: Data
    ) throws -> CookleDataArchive {
        try decoder.decode(
            CookleDataArchive.self,
            from: data
        )
    }

    /// Decodes and validates JSON backup data before restore confirmation.
    public static func validatedArchive(
        from data: Data
    ) throws -> CookleDataArchive {
        let archive = try decodedArchive(
            from: data
        )
        try validate(archive)
        return archive
    }

    /// Replaces current persisted user data with the supplied validated archive.
    public static func restore(
        _ archive: CookleDataArchive,
        context: ModelContext
    ) throws -> CookleDataRestoreSummary {
        try validate(archive)
        try DataResetService.deleteAll(context: context)

        let categories = try restoreCategories(
            archive.categories,
            context: context
        )
        let ingredients = try restoreIngredients(
            archive.ingredients,
            context: context
        )
        let photos = try restorePhotos(
            archive.photos,
            context: context
        )
        let recipes = try restoreRecipes(
            archive.recipes,
            context: context,
            photos: photos,
            ingredients: ingredients,
            categories: categories
        )
        try restoreDiaries(
            archive.diaries,
            context: context,
            recipes: recipes
        )
        try context.save()

        return .init(
            ingredientCount: archive.ingredients.count,
            categoryCount: archive.categories.count,
            photoCount: archive.photos.count,
            recipeCount: archive.recipes.count,
            diaryCount: archive.diaries.count
        )
    }
}
