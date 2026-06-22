@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("DeletionPolicyAudit.ObjectLifecycle")
struct DeletionPolicyAuditObjectLifecycleTests {
    @Test
    func update_recipe_replaces_photo_objects_and_cleans_up_old_rows() throws {
        let context = makeTestContext()
        let firstPhotoData = DeletionPolicyAuditSupport.makePhotoData("first")
        let secondPhotoData = DeletionPolicyAuditSupport.makePhotoData("second")
        let recipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Photo Update",
            photos: [firstPhotoData],
            ingredients: [],
            categories: []
        )
        try context.save()

        RecipeFormService.update(
            context: context,
            recipe: recipe,
            draft: DeletionPolicyAuditSupport.draft(
                name: "Photo Update",
                photos: [secondPhotoData],
                ingredients: []
            )
        )
        try context.save()

        let verificationContext = DeletionPolicyAuditSupport.reloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentPhoto = try #require(persistedRecipe.orderedPhotos.first)
        let photoObjects = try verificationContext.fetch(FetchDescriptor<PhotoObject>())
        let removedPhoto = try DeletionPolicyAuditSupport.requirePhoto(
            matching: firstPhotoData.data,
            in: try verificationContext.fetch(.photos(.all))
        )
        #expect(photoObjects.count == 1)
        #expect(try DeletionPolicyAuditSupport.count(of: Photo.self, in: verificationContext) == 2)
        #expect(persistedRecipe.orderedPhotoObjects.count == 1)
        #expect(currentPhoto.data == secondPhotoData.data)
        #expect((removedPhoto.recipes ?? []).isEmpty)
        #expect((removedPhoto.objects ?? []).isEmpty)
    }

    @Test
    func update_recipe_replaces_ingredient_objects_and_cleans_up_old_rows() throws {
        let context = makeTestContext()
        let recipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Ingredient Update",
            photos: [],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: []
        )
        try context.save()

        RecipeFormService.update(
            context: context,
            recipe: recipe,
            draft: DeletionPolicyAuditSupport.draft(
                name: "Ingredient Update",
                photos: [],
                ingredients: [.init(ingredient: "Pepper", amount: "1 tsp")]
            )
        )
        try context.save()

        let verificationContext = DeletionPolicyAuditSupport.reloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentIngredient = try #require(
            (persistedRecipe.ingredientObjects ?? []).first?.ingredient
        )
        let ingredientObjects = try verificationContext.fetch(
            FetchDescriptor<IngredientObject>()
        )
        let removedIngredient = try requireIngredient(
            named: "Salt",
            in: try verificationContext.fetch(.ingredients(.all))
        )
        #expect(ingredientObjects.count == 1)
        #expect(
            try DeletionPolicyAuditSupport.count(
                of: Ingredient.self,
                in: verificationContext
            ) == 2
        )
        #expect((persistedRecipe.ingredientObjects ?? []).count == 1)
        #expect(currentIngredient.value == "Pepper")
        #expect((removedIngredient.recipes ?? []).isEmpty)
        #expect((removedIngredient.objects ?? []).isEmpty)
    }

    @Test
    func update_diary_replaces_old_diary_objects_and_cleans_up_old_rows() throws {
        let context = makeTestContext()
        let firstRecipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Breakfast"
        )
        let secondRecipe = DeletionPolicyAuditSupport.makeRecipe(
            context: context,
            name: "Lunch"
        )
        let diary = DiaryService.create(
            context: context,
            input: .init(
                date: .now,
                breakfasts: [firstRecipe]
            )
        )
        try context.save()
        let removedObjectID = try #require(
            (diary.objects ?? []).first?.persistentModelID
        )

        DiaryService.update(
            context: context,
            diary: diary,
            input: .init(
                date: diary.date,
                lunches: [secondRecipe],
                note: "updated"
            )
        )
        try context.save()

        let verificationContext = DeletionPolicyAuditSupport.reloadedContext(from: context)
        let persistedDiary = try #require(
            verificationContext.fetch(.diaries(.all)).first
        )
        let diaryObjects = try verificationContext.fetch(FetchDescriptor<DiaryObject>())
        try assertUpdatedDiaryObjects(
            diaryObjects: diaryObjects,
            persistedDiary: persistedDiary,
            removedObjectID: removedObjectID,
            secondRecipe: secondRecipe
        )
    }
}

private func requireIngredient(
    named value: String,
    in ingredients: [Ingredient]
) throws -> Ingredient {
    try #require(
        ingredients.first { ingredient in
            ingredient.value == value
        }
    )
}

private func assertUpdatedDiaryObjects(
    diaryObjects: [DiaryObject],
    persistedDiary: Diary,
    removedObjectID: PersistentIdentifier,
    secondRecipe: Recipe
) throws {
    let attachedObject = try #require(
        (persistedDiary.objects ?? []).first
    )

    #expect(diaryObjects.count == 1)
    #expect((persistedDiary.objects ?? []).count == 1)
    #expect(attachedObject.persistentModelID != removedObjectID)
    #expect(attachedObject.recipe?.persistentModelID == secondRecipe.persistentModelID)
    #expect(attachedObject.type == .lunch)
    #expect(
        diaryObjects.contains { diaryObject in
            diaryObject.persistentModelID == removedObjectID
        } == false
    )
}
