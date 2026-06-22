extension CookleDataArchiveService {
    static func validate(
        _ archive: CookleDataArchive
    ) throws {
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

    static func uniqueIDs(
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

    static func validateRecipeReferences(
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

    static func validateDiaryReferences(
        _ diaries: [CookleDataArchive.DiaryRecord],
        recipeIDs: Set<String>
    ) throws {
        for diary in diaries {
            for object in diary.objects where recipeIDs.contains(object.recipeID) == false {
                throw ArchiveError.missingReference(object.recipeID)
            }
        }
    }
}
