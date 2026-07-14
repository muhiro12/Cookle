import Foundation

extension CookleDataArchiveService {
    nonisolated static func validate(
        _ archive: CookleDataArchive,
        calendar: Calendar,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try CookleDataArchiveResourceValidator.validate(
            archive,
            limits: limits
        )
        guard archive.formatVersion == CookleDataArchive.currentFormatVersion else {
            throw ArchiveError.unsupportedFormatVersion(
                archive.formatVersion
            )
        }

        let ingredientIDs = try uniqueIDs(
            archive.ingredients.map(\.id)
        )
        let categoryIDs = try uniqueIDs(
            archive.categories.map(\.id)
        )
        let photoIDs = try uniqueIDs(
            archive.photos.map(\.id)
        )
        let recipeIDs = try uniqueIDs(
            archive.recipes.map(\.id)
        )
        _ = try uniqueIDs(
            archive.diaries.map(\.id)
        )
        try validateDiaryDays(
            archive.diaries,
            calendar: calendar
        )
        try validateRecipeReferences(
            archive.recipes,
            photoIDs: photoIDs,
            ingredientIDs: ingredientIDs,
            categoryIDs: categoryIDs
        )
        try validateDiaryReferences(
            archive.diaries,
            recipeIDs: recipeIDs
        )
    }

    nonisolated static func uniqueIDs(
        _ identifiers: [String]
    ) throws -> Set<String> {
        var result = Set<String>()
        for identifier in identifiers {
            guard result.insert(identifier).inserted else {
                throw ArchiveError.duplicateIdentifier(identifier)
            }
        }
        return result
    }

    nonisolated static func validateRecipeReferences(
        _ recipes: [CookleDataArchive.RecipeRecord],
        photoIDs: Set<String>,
        ingredientIDs: Set<String>,
        categoryIDs: Set<String>
    ) throws {
        for recipe in recipes {
            for photo in recipe.photos where photoIDs.contains(photo.photoID) == false {
                throw ArchiveError.missingReference(photo.photoID)
            }
            for ingredient in recipe.ingredients where ingredientIDs.contains(ingredient.ingredientID) == false {
                throw ArchiveError.missingReference(ingredient.ingredientID)
            }
            for categoryID in recipe.categoryIDs where categoryIDs.contains(categoryID) == false {
                throw ArchiveError.missingReference(categoryID)
            }
        }
    }

    nonisolated static func validateDiaryReferences(
        _ diaries: [CookleDataArchive.DiaryRecord],
        recipeIDs: Set<String>
    ) throws {
        for diary in diaries {
            for object in diary.objects where recipeIDs.contains(object.recipeID) == false {
                throw ArchiveError.missingReference(object.recipeID)
            }
        }
    }

    nonisolated static func validateDiaryDays(
        _ diaries: [CookleDataArchive.DiaryRecord],
        calendar: Calendar
    ) throws {
        var occupiedDays = Set<Date>()
        for diary in diaries {
            let day = calendar.startOfDay(
                for: diary.date
            )
            guard occupiedDays.insert(day).inserted else {
                throw ArchiveError.duplicateDiaryDay
            }
        }
    }
}
