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
        let sharedPhotoData = DeletionPolicyAuditSupport.makePhotoData("shared")
        let uniquePhotoData = DeletionPolicyAuditSupport.makePhotoData("unique")

        let recipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Delete Target",
            photos: [sharedPhotoData, uniquePhotoData],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: []
        )
        let remainingRecipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Remaining",
            photos: [sharedPhotoData],
            ingredients: [],
            categories: []
        )
        let diary = DiaryService.create(
            context: context,
            input: .init(
                date: .now,
                breakfasts: [recipe],
                lunches: [],
                dinners: [],
                note: ""
            )
        )
        try context.save()

        RecipeService.delete(
            context: context,
            recipe: recipe
        )
        try context.save()

        let photos = try context.fetch(.photos(.all))
        let orphanedPhoto = try DeletionPolicyAuditSupport.requirePhoto(
            matching: uniquePhotoData.data,
            in: photos
        )
        let sharedPhoto = try DeletionPolicyAuditSupport.requirePhoto(
            matching: sharedPhotoData.data,
            in: photos
        )

        try assertRecipeDeletionCounts(context: context)
        #expect(remainingRecipe.orderedPhotos.count == 1)
        #expect((diary.objects ?? []).isEmpty)
        #expect((orphanedPhoto.recipes ?? []).isEmpty)
        #expect((orphanedPhoto.objects ?? []).isEmpty)
        #expect((sharedPhoto.recipes ?? []).count == 1)
    }

    @Test
    func data_reset_removes_every_persisted_model() throws {
        let context = makeTestContext()
        let recipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Reset Target",
            photos: [DeletionPolicyAuditSupport.makePhotoData("reset")],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: ["Dinner"]
        )
        _ = DiaryService.create(
            context: context,
            input: .init(
                date: .now,
                breakfasts: [recipe],
                lunches: [],
                dinners: [],
                note: ""
            )
        )
        try context.save()

        _ = try DataResetService.deleteAllWithOutcome(
            context: context
        )
        try context.save()

        let counts = try DeletionPolicyAuditSupport.modelCounts(
            context: DeletionPolicyAuditSupport.reloadedContext(from: context)
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

private func assertRecipeDeletionCounts(
    context: ModelContext
) throws {
    let expectedRemainingRecipeCount = 1
    let expectedRemainingPhotoObjectCount = 1
    let expectedDeletedSubobjectCount = 0
    let expectedRemainingPhotoCount = 2
    let expectedRemainingIngredientCount = 1
    let expectedRemainingDiaryCount = 1

    #expect(
        try DeletionPolicyAuditSupport.count(of: Recipe.self, in: context)
            == expectedRemainingRecipeCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: PhotoObject.self, in: context)
            == expectedRemainingPhotoObjectCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: IngredientObject.self, in: context)
            == expectedDeletedSubobjectCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: DiaryObject.self, in: context)
            == expectedDeletedSubobjectCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: Photo.self, in: context)
            == expectedRemainingPhotoCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: Ingredient.self, in: context)
            == expectedRemainingIngredientCount
    )
    #expect(
        try DeletionPolicyAuditSupport.count(of: Diary.self, in: context)
            == expectedRemainingDiaryCount
    )
}
