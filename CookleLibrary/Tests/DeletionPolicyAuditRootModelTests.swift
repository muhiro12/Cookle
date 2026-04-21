@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("DeletionPolicyAudit.RootModels")
struct DeletionPolicyAuditRootModelTests {
    @Test
    func delete_recipe_cascades_subobjects_but_keeps_photo_and_ingredient_records() throws {
        let context = makeTestContext()
        let sharedPhotoData = makeAuditPhotoData("shared")
        let uniquePhotoData = makeAuditPhotoData("unique")

        let recipe = makeAuditRecipe(
            context: context,
            name: "Delete Target",
            photos: [sharedPhotoData, uniquePhotoData],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: []
        )
        let remainingRecipe = makeAuditRecipe(
            context: context,
            name: "Remaining",
            photos: [sharedPhotoData],
            ingredients: [],
            categories: []
        )
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [recipe],
            lunches: [],
            dinners: [],
            note: ""
        )
        try context.save()

        RecipeService.delete(
            context: context,
            recipe: recipe
        )
        try context.save()

        let photos = try context.fetch(.photos(.all))
        let orphanedPhoto = try requirePhoto(
            matching: uniquePhotoData.data,
            in: photos
        )
        let sharedPhoto = try requirePhoto(
            matching: sharedPhotoData.data,
            in: photos
        )

        #expect(try auditCount(of: Recipe.self, in: context) == 1)
        #expect(try auditCount(of: PhotoObject.self, in: context) == 1)
        #expect(try auditCount(of: IngredientObject.self, in: context) == 0)
        #expect(try auditCount(of: DiaryObject.self, in: context) == 0)
        #expect(try auditCount(of: Photo.self, in: context) == 2)
        #expect(try auditCount(of: Ingredient.self, in: context) == 1)
        #expect(try auditCount(of: Diary.self, in: context) == 1)
        #expect(remainingRecipe.orderedPhotos.count == 1)
        #expect(diary.objects.orEmpty.isEmpty)
        #expect(orphanedPhoto.recipes.orEmpty.isEmpty)
        #expect(orphanedPhoto.objects.orEmpty.isEmpty)
        #expect(sharedPhoto.recipes.orEmpty.count == 1)
    }

    @Test
    func delete_in_use_category_keeps_recipe_and_drops_relationship() throws {
        let context = makeTestContext()
        let recipe = makeAuditRecipe(
            context: context,
            name: "Category Delete",
            photos: [],
            ingredients: [],
            categories: ["Dinner"]
        )
        let category = try #require(recipe.categories.orEmpty.first)
        try context.save()

        TagService.delete(
            context: context,
            category: category
        )
        try context.save()

        let persistedRecipe = try #require(
            context.fetch(.recipes(.all)).first
        )

        #expect(try auditCount(of: Category.self, in: context) == 0)
        #expect(try auditCount(of: Recipe.self, in: context) == 1)
        #expect(persistedRecipe.categories.orEmpty.isEmpty)
    }

    @Test
    func data_reset_removes_every_persisted_model() throws {
        let context = makeTestContext()
        let recipe = makeAuditRecipe(
            context: context,
            name: "Reset Target",
            photos: [makeAuditPhotoData("reset")],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: ["Dinner"]
        )
        _ = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [recipe],
            lunches: [],
            dinners: [],
            note: ""
        )
        try context.save()

        _ = try DataResetService.deleteAllWithOutcome(
            context: context
        )
        try context.save()

        let counts = try auditModelCounts(
            context: auditReloadedContext(from: context)
        )

        #expect(counts.recipeCount == 0)
        #expect(counts.diaryCount == 0)
        #expect(counts.photoCount == 0)
        #expect(counts.categoryCount == 0)
        #expect(counts.ingredientCount == 0)
        #expect(counts.diaryObjectCount == 0)
        #expect(counts.photoObjectCount == 0)
        #expect(counts.ingredientObjectCount == 0)
    }
}
