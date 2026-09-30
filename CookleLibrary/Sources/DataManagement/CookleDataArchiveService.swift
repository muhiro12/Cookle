import Foundation
import SwiftData

/// Internal archive collaborator used by data maintenance Operations.
@preconcurrency
@MainActor
enum CookleDataArchiveService {
    enum ArchiveError: LocalizedError, Sendable {
        case duplicateIdentifier(String)
        case duplicateDiaryDay
        case missingReference(String)
        case resourceByteCountExceeded(
                category: CookleDataArchiveResourceCategory,
                actualByteCount: Int,
                maximumByteCount: Int
             )
        case resourceCountExceeded(
                category: CookleDataArchiveResourceCategory,
                actualCount: Int,
                maximumCount: Int
             )

        var errorDescription: String? {
            switch self {
            case .duplicateIdentifier(let identifier):
                "Export file contains a duplicate identifier: \(identifier)"
            case .duplicateDiaryDay:
                "Export file contains multiple diaries for the same calendar day."
            case .missingReference(let identifier):
                "Export file is missing referenced data: \(identifier)"
            case let .resourceByteCountExceeded(
                category,
                actualByteCount,
                maximumByteCount
            ):
                """
                Export file \(category.rawValue) uses \(actualByteCount) bytes, \
                exceeding the \(maximumByteCount)-byte limit.
                """
            case let .resourceCountExceeded(
                category,
                actualCount,
                maximumCount
            ):
                """
                Export file contains \(actualCount) \(category.rawValue), exceeding the limit of \(maximumCount).
                """
            }
        }
    }

    /// Builds an in-memory archive from the current persisted user data.
    static func makeArchive(
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
            scope: .all,
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

    /// Replaces all current persisted user data with a complete-library archive.
    ///
    /// Nothing changes unless the archive covers the whole library and passes
    /// validation; any failure rolls the context back before rethrowing.
    static func replaceAll(
        with archive: CookleDataArchive,
        context: ModelContext,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard,
        save: (ModelContext) throws -> Void = { context in
            try context.save()
        }
    ) throws -> CookleDataReplacementSummary {
        try Task.checkCancellation()
        guard context.hasChanges == false else {
            throw CookleDataImportError.pendingChanges
        }
        guard archive.scope == .all else {
            throw CookleDataImportError.replacementRequiresCompleteArchive
        }
        try validate(
            archive,
            calendar: calendar,
            limits: limits
        )

        do {
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
            try save(context)
        } catch {
            context.rollback()
            throw error
        }

        return .init(
            ingredientCount: archive.ingredients.count,
            categoryCount: archive.categories.count,
            photoCount: archive.photos.count,
            recipeCount: archive.recipes.count,
            diaryCount: archive.diaries.count
        )
    }
}
