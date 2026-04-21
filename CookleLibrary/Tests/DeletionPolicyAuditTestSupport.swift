@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

struct DeletionPolicyAuditIngredientInput {
    let ingredient: String
    let amount: String
}

struct DeletionPolicyAuditModelCounts {
    let recipeCount: Int
    let diaryCount: Int
    let photoCount: Int
    let categoryCount: Int
    let ingredientCount: Int
    let diaryObjectCount: Int
    let photoObjectCount: Int
    let ingredientObjectCount: Int
}

private enum DeletionPolicyAuditValues {
    static let servingSize = 1
    static let cookingTimeMinutes = 10
}

func makeAuditPhotoData(
    _ identifier: String
) -> PhotoData {
    .init(
        data: Data(identifier.utf8),
        source: .photosPicker
    )
}

func makeAuditRecipe(
    context: ModelContext,
    name: String,
    photos: [PhotoData],
    ingredients: [DeletionPolicyAuditIngredientInput],
    categories: [String]
) -> Recipe {
    Recipe.create(
        context: context,
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
        servingSize: DeletionPolicyAuditValues.servingSize,
        cookingTime: DeletionPolicyAuditValues.cookingTimeMinutes,
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
}

func auditDraft(
    name: String,
    photos: [PhotoData],
    ingredients: [RecipeFormIngredientInput]
) -> RecipeFormDraft {
    .init(
        name: name,
        photos: photos,
        servingSize: DeletionPolicyAuditValues.servingSize,
        cookingTime: DeletionPolicyAuditValues.cookingTimeMinutes,
        ingredients: ingredients,
        steps: [],
        categories: [],
        note: ""
    )
}

func auditCount<Model: PersistentModel>(
    of _: Model.Type,
    in context: ModelContext
) throws -> Int {
    try context.fetchCount(FetchDescriptor<Model>())
}

func auditModelCounts(
    context: ModelContext
) throws -> DeletionPolicyAuditModelCounts {
    try .init(
        recipeCount: auditCount(of: Recipe.self, in: context),
        diaryCount: auditCount(of: Diary.self, in: context),
        photoCount: auditCount(of: Photo.self, in: context),
        categoryCount: auditCount(of: Category.self, in: context),
        ingredientCount: auditCount(of: Ingredient.self, in: context),
        diaryObjectCount: auditCount(of: DiaryObject.self, in: context),
        photoObjectCount: auditCount(of: PhotoObject.self, in: context),
        ingredientObjectCount: auditCount(of: IngredientObject.self, in: context)
    )
}

func auditReloadedContext(
    from context: ModelContext
) -> ModelContext {
    .init(context.container)
}

func requirePhoto(
    matching data: Data,
    in photos: [Photo]
) throws -> Photo {
    try #require(
        photos.first { photo in
            photo.data == data
        }
    )
}
