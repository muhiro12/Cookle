import Foundation

enum CookleDataArchiveResourceValidator {
    typealias ArchiveError = CookleDataArchiveService.ArchiveError
    typealias ResourceCategory = CookleDataArchiveResourceCategory

    static func validateEncodedData(
        _ data: Data,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateByteCount(
            data.count,
            maximumByteCount: limits.maximumEncodedByteCount,
            category: .encodedData
        )
    }

    static func validate(
        _ archive: CookleDataArchive,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateTopLevelRecordCounts(
            archive,
            limits: limits
        )
        try validateTags(
            archive,
            limits: limits
        )

        var aggregatePhotoByteCount = 0
        try validatePhotos(
            archive.photos,
            aggregatePhotoByteCount: &aggregatePhotoByteCount,
            limits: limits
        )

        var aggregateNestedRecordCount = 0
        try validateRecipes(
            archive.recipes,
            aggregateNestedRecordCount: &aggregateNestedRecordCount,
            limits: limits
        )
        try validateDiaries(
            archive.diaries,
            aggregateNestedRecordCount: &aggregateNestedRecordCount,
            limits: limits
        )
    }
}

private extension CookleDataArchiveResourceValidator {
    static func validateTopLevelRecordCounts(
        _ archive: CookleDataArchive,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateCount(
            archive.ingredients.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .ingredientRecords
        )
        try validateCount(
            archive.categories.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .categoryRecords
        )
        try validateCount(
            archive.photos.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .photoRecords
        )
        try validateCount(
            archive.recipes.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .recipeRecords
        )
        try validateCount(
            archive.diaries.count,
            maximumCount: limits.maximumTopLevelRecordCountPerCategory,
            category: .diaryRecords
        )
    }

    static func validateTags(
        _ archive: CookleDataArchive,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        for ingredient in archive.ingredients {
            try validateIdentifier(
                ingredient.id,
                limits: limits
            )
            try validateText(
                ingredient.value,
                limits: limits
            )
        }
        for category in archive.categories {
            try validateIdentifier(
                category.id,
                limits: limits
            )
            try validateText(
                category.value,
                limits: limits
            )
        }
    }

    static func validatePhotos(
        _ photos: [CookleDataArchive.PhotoRecord],
        aggregatePhotoByteCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        for photo in photos {
            try validateIdentifier(
                photo.id,
                limits: limits
            )
            try validateIdentifier(
                photo.sourceID,
                limits: limits
            )
            try validateByteCount(
                photo.data.count,
                maximumByteCount: limits.maximumPhotoByteCount,
                category: .photoData
            )
            try addByteCount(
                photo.data.count,
                to: &aggregatePhotoByteCount,
                maximumByteCount: limits.maximumAggregatePhotoByteCount,
                category: .aggregatePhotoData
            )
        }
    }

    static func validateRecipes(
        _ recipes: [CookleDataArchive.RecipeRecord],
        aggregateNestedRecordCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        for recipe in recipes {
            try validateRecipe(
                recipe,
                aggregateNestedRecordCount: &aggregateNestedRecordCount,
                limits: limits
            )
        }
    }

    static func validateRecipe(
        _ recipe: CookleDataArchive.RecipeRecord,
        aggregateNestedRecordCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateIdentifier(
            recipe.id,
            limits: limits
        )
        try validateText(
            recipe.name,
            limits: limits
        )
        try validateText(
            recipe.note,
            limits: limits
        )
        try addRecipeNestedRecordCounts(
            recipe,
            to: &aggregateNestedRecordCount,
            limits: limits
        )
        try validateRecipeContent(
            recipe,
            limits: limits
        )
    }

    static func addRecipeNestedRecordCounts(
        _ recipe: CookleDataArchive.RecipeRecord,
        to aggregateNestedRecordCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try addNestedRecordCount(
            recipe.photos.count,
            to: &aggregateNestedRecordCount,
            limits: limits
        )
        try addNestedRecordCount(
            recipe.ingredients.count,
            to: &aggregateNestedRecordCount,
            limits: limits
        )
        try addNestedRecordCount(
            recipe.steps.count,
            to: &aggregateNestedRecordCount,
            limits: limits
        )
        try addNestedRecordCount(
            recipe.categoryIDs.count,
            to: &aggregateNestedRecordCount,
            limits: limits
        )
    }

    static func validateRecipeContent(
        _ recipe: CookleDataArchive.RecipeRecord,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        for photo in recipe.photos {
            try validateIdentifier(
                photo.photoID,
                limits: limits
            )
        }
        for ingredient in recipe.ingredients {
            try validateIdentifier(
                ingredient.ingredientID,
                limits: limits
            )
            try validateText(
                ingredient.amount,
                limits: limits
            )
        }
        for step in recipe.steps {
            try validateText(
                step,
                limits: limits
            )
        }
        for categoryID in recipe.categoryIDs {
            try validateIdentifier(
                categoryID,
                limits: limits
            )
        }
    }

    static func validateDiaries(
        _ diaries: [CookleDataArchive.DiaryRecord],
        aggregateNestedRecordCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        for diary in diaries {
            try validateIdentifier(
                diary.id,
                limits: limits
            )
            try validateText(
                diary.note,
                limits: limits
            )
            try addNestedRecordCount(
                diary.objects.count,
                to: &aggregateNestedRecordCount,
                limits: limits
            )
            for object in diary.objects {
                try validateIdentifier(
                    object.recipeID,
                    limits: limits
                )
            }
        }
    }

    static func validateIdentifier(
        _ identifier: String,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateByteCount(
            identifier.utf8.count,
            maximumByteCount: limits.maximumIdentifierByteCount,
            category: .identifier
        )
    }

    static func validateText(
        _ text: String,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        try validateByteCount(
            text.utf8.count,
            maximumByteCount: limits.maximumTextByteCount,
            category: .text
        )
    }

    static func addNestedRecordCount(
        _ count: Int,
        to aggregateCount: inout Int,
        limits: CookleDataArchiveResourceLimits
    ) throws {
        let (newCount, overflowed) = aggregateCount.addingReportingOverflow(
            count
        )
        guard overflowed == false else {
            throw ArchiveError.resourceCountExceeded(
                category: .nestedRecords,
                actualCount: .max,
                maximumCount: limits.maximumAggregateNestedRecordCount
            )
        }
        try validateCount(
            newCount,
            maximumCount: limits.maximumAggregateNestedRecordCount,
            category: .nestedRecords
        )
        aggregateCount = newCount
    }

    static func addByteCount(
        _ byteCount: Int,
        to aggregateByteCount: inout Int,
        maximumByteCount: Int,
        category: ResourceCategory
    ) throws {
        let (newByteCount, overflowed) = aggregateByteCount.addingReportingOverflow(
            byteCount
        )
        guard overflowed == false else {
            throw ArchiveError.resourceByteCountExceeded(
                category: category,
                actualByteCount: .max,
                maximumByteCount: maximumByteCount
            )
        }
        try validateByteCount(
            newByteCount,
            maximumByteCount: maximumByteCount,
            category: category
        )
        aggregateByteCount = newByteCount
    }

    static func validateCount(
        _ count: Int,
        maximumCount: Int,
        category: ResourceCategory
    ) throws {
        guard count <= maximumCount else {
            throw ArchiveError.resourceCountExceeded(
                category: category,
                actualCount: count,
                maximumCount: maximumCount
            )
        }
    }

    static func validateByteCount(
        _ byteCount: Int,
        maximumByteCount: Int,
        category: ResourceCategory
    ) throws {
        guard byteCount <= maximumByteCount else {
            throw ArchiveError.resourceByteCountExceeded(
                category: category,
                actualByteCount: byteCount,
                maximumByteCount: maximumByteCount
            )
        }
    }
}
