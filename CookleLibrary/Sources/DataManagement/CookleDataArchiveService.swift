import Foundation
import SwiftData

/// Internal archive collaborator used by data maintenance Operations.
@preconcurrency
@MainActor
enum CookleDataArchiveService {
    enum ArchiveError: LocalizedError, Sendable {
        case unsupportedFormatVersion(Int)
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
            case .unsupportedFormatVersion(let version):
                "Unsupported backup format version: \(version)"
            case .duplicateIdentifier(let identifier):
                "Backup contains a duplicate identifier: \(identifier)"
            case .duplicateDiaryDay:
                "Backup contains multiple diaries for the same calendar day."
            case .missingReference(let identifier):
                "Backup is missing referenced data: \(identifier)"
            case let .resourceByteCountExceeded(
                category,
                actualByteCount,
                maximumByteCount
            ):
                """
                Backup \(category.rawValue) uses \(actualByteCount) bytes, exceeding the \(maximumByteCount)-byte limit.
                """
            case let .resourceCountExceeded(
                category,
                actualCount,
                maximumCount
            ):
                """
                Backup contains \(actualCount) \(category.rawValue), exceeding the limit of \(maximumCount).
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
    static func encodedArchive(
        from context: ModelContext,
        limits: CookleDataArchiveResourceLimits = .standard
    ) throws -> Data {
        let archive = try makeArchive(
            context: context
        )
        try CookleDataArchiveResourceValidator.validate(
            archive,
            limits: limits
        )
        let data = try encoder.encode(
            archive
        )
        try CookleDataArchiveResourceValidator.validateEncodedData(
            data,
            limits: limits
        )
        return data
    }

    /// Decodes JSON backup data without applying it to the store.
    nonisolated static func decodedArchive(
        from data: Data,
        limits: CookleDataArchiveResourceLimits = .standard
    ) throws -> CookleDataArchive {
        try CookleDataArchiveResourceValidator.validateEncodedData(
            data,
            limits: limits
        )
        return try decoder.decode(
            CookleDataArchive.self,
            from: data
        )
    }

    /// Decodes and validates JSON backup data before restore confirmation.
    nonisolated static func validatedArchive(
        from data: Data,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard
    ) throws -> CookleDataArchive {
        let archive = try decodedArchive(
            from: data,
            limits: limits
        )
        try validate(
            archive,
            calendar: calendar,
            limits: limits
        )
        return archive
    }

    /// Replaces current persisted user data with the supplied validated archive.
    static func restore(
        _ archive: CookleDataArchive,
        context: ModelContext,
        calendar: Calendar = .current,
        limits: CookleDataArchiveResourceLimits = .standard,
        save: (ModelContext) throws -> Void = { context in
            try context.save()
        }
    ) throws -> CookleDataRestoreSummary {
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
