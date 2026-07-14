@testable import CookleLibrary
import Foundation

enum ArchiveResourceLimitTestSupport {
    static func makeLimits(
        maximumEncodedByteCount: Int = 1_000_000,
        maximumManifestByteCount: Int = 1_000_000,
        maximumPackageByteCount: Int = 2_000_000,
        maximumTopLevelRecordCountPerCategory: Int = 10,
        maximumAggregateNestedRecordCount: Int = 100,
        maximumIdentifierByteCount: Int = 128,
        maximumTextByteCount: Int = 128,
        maximumPhotoByteCount: Int = 128,
        maximumAggregatePhotoByteCount: Int = 256
    ) -> CookleDataArchiveResourceLimits {
        .init(
            maximumEncodedByteCount: maximumEncodedByteCount,
            maximumManifestByteCount: maximumManifestByteCount,
            maximumPackageByteCount: maximumPackageByteCount,
            maximumTopLevelRecordCountPerCategory: maximumTopLevelRecordCountPerCategory,
            maximumAggregateNestedRecordCount: maximumAggregateNestedRecordCount,
            maximumIdentifierByteCount: maximumIdentifierByteCount,
            maximumTextByteCount: maximumTextByteCount,
            maximumPhotoByteCount: maximumPhotoByteCount,
            maximumAggregatePhotoByteCount: maximumAggregatePhotoByteCount
        )
    }

    static func encodedData(
        from archive: CookleDataArchive
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(
            archive
        )
    }

    static func makeArchive(
        ingredients: [CookleDataArchive.IngredientRecord] = [],
        photos: [CookleDataArchive.PhotoRecord] = [],
        recipes: [CookleDataArchive.RecipeRecord] = []
    ) -> CookleDataArchive {
        .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
            exportedAt: .now,
            ingredients: ingredients,
            categories: [],
            photos: photos,
            recipes: recipes,
            diaries: []
        )
    }

    static func makeIngredient(
        id: String = "ingredient-1",
        value: String = "Ingredient"
    ) -> CookleDataArchive.IngredientRecord {
        .init(
            id: id,
            value: value,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    static func makePhoto(
        data: Data,
        id: String = "photo-1"
    ) -> CookleDataArchive.PhotoRecord {
        .init(
            id: id,
            data: data,
            sourceID: "source-1",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    static func makeRecipe(
        id: String,
        steps: [String]
    ) -> CookleDataArchive.RecipeRecord {
        .init(
            id: id,
            name: "Recipe",
            photos: [],
            servingSize: 1,
            cookingTime: 1,
            ingredients: [],
            steps: steps,
            categoryIDs: [],
            note: "",
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }
}
