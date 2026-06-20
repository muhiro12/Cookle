@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

enum DeletionPolicyAuditSupport {
    static let servingSize = 1
    static let cookingTimeMinutes = 10

    static func makePhotoData(
        _ identifier: String
    ) -> PhotoData {
        .init(
            data: Data(identifier.utf8),
            source: .photosPicker
        )
    }

    static func makeRecipe(
        context: ModelContext,
        name: String,
        photos: [PhotoData] = [],
        ingredients: [DeletionPolicyAuditIngredientInput] = [],
        categories: [String] = []
    ) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: zip(
                    photos.indices,
                    photos
                ).map { index, photoData in
                    PhotoObject.create(
                        context: context,
                        photoData: photoData,
                        order: index + 1
                    )
                },
                servingSize: servingSize,
                cookingTime: cookingTimeMinutes,
                ingredients: zip(
                    ingredients.indices,
                    ingredients
                ).map { index, ingredient in
                    IngredientObject.create(
                        context: context,
                        ingredient: ingredient.ingredient,
                        amount: ingredient.amount,
                        order: index + 1
                    )
                },
                steps: [],
                categories: categories.map { value in
                    Category.create(
                        context: context,
                        value: value
                    )
                },
                note: ""
            )
        )
    }

    static func draft(
        name: String,
        photos: [PhotoData],
        ingredients: [RecipeFormIngredientInput]
    ) -> RecipeFormDraft {
        .init(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTimeMinutes,
            ingredients: ingredients,
            steps: [],
            categories: [],
            note: ""
        )
    }

    static func count<Model: PersistentModel>(
        of _: Model.Type,
        in context: ModelContext
    ) throws -> Int {
        try context.fetchCount(FetchDescriptor<Model>())
    }

    static func modelCounts(
        context: ModelContext
    ) throws -> DeletionPolicyAuditModelCounts {
        try .init(
            recipeCount: count(of: Recipe.self, in: context),
            diaryCount: count(of: Diary.self, in: context),
            photoCount: count(of: Photo.self, in: context),
            categoryCount: count(of: Category.self, in: context),
            ingredientCount: count(of: Ingredient.self, in: context),
            diaryObjectCount: count(of: DiaryObject.self, in: context),
            photoObjectCount: count(of: PhotoObject.self, in: context),
            ingredientObjectCount: count(of: IngredientObject.self, in: context)
        )
    }

    static func reloadedContext(
        from context: ModelContext
    ) -> ModelContext {
        .init(context.container)
    }

    static func requirePhoto(
        matching data: Data,
        in photos: [Photo]
    ) throws -> Photo {
        try #require(
            photos.first { photo in
                photo.data == data
            }
        )
    }
}
