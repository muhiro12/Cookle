@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("DeletionPolicyAudit.ObjectLifecycle")
struct DeletionPolicyAuditObjectLifecycleTests {
    @Test
    func update_recipe_replaces_photo_objects_but_leaves_removed_photo_asset_orphaned() throws {
        let context = makeTestContext()
        let firstPhotoData = makeAuditPhotoData("first")
        let secondPhotoData = makeAuditPhotoData("second")
        let recipe = makeAuditRecipe(
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
            draft: auditDraft(
                name: "Photo Update",
                photos: [secondPhotoData],
                ingredients: []
            )
        )
        try context.save()

        let verificationContext = auditReloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentPhoto = try #require(persistedRecipe.orderedPhotos.first)
        let photoObjects = try verificationContext.fetch(FetchDescriptor<PhotoObject>())
        let removedPhoto = try requirePhoto(
            matching: firstPhotoData.data,
            in: try verificationContext.fetch(.photos(.all))
        )
        let removedPhotoObject = try requirePhotoObject(
            matching: firstPhotoData.data,
            in: photoObjects
        )

        #expect(photoObjects.count == 2)
        #expect(try auditCount(of: Photo.self, in: verificationContext) == 2)
        #expect(persistedRecipe.orderedPhotoObjects.count == 1)
        #expect(currentPhoto.data == secondPhotoData.data)
        #expect(removedPhoto.recipes.orEmpty.isEmpty)
        #expect(removedPhoto.objects.orEmpty.count == 1)
        #expect(removedPhotoObject.recipe == nil)
    }

    @Test
    func update_recipe_replaces_ingredient_objects_but_leaves_removed_ingredient_orphaned() throws {
        let context = makeTestContext()
        let recipe = makeAuditRecipe(
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
            draft: auditDraft(
                name: "Ingredient Update",
                photos: [],
                ingredients: [.init(ingredient: "Pepper", amount: "1 tsp")]
            )
        )
        try context.save()

        let verificationContext = auditReloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentIngredient = try #require(
            persistedRecipe.ingredientObjects.orEmpty.first?.ingredient
        )
        let ingredientObjects = try verificationContext.fetch(
            FetchDescriptor<IngredientObject>()
        )
        let removedIngredient = try requireIngredient(
            named: "Salt",
            in: try verificationContext.fetch(.ingredients(.all))
        )
        let removedIngredientObject = try requireIngredientObject(
            named: "Salt",
            in: ingredientObjects
        )

        #expect(ingredientObjects.count == 2)
        #expect(try auditCount(of: Ingredient.self, in: verificationContext) == 2)
        #expect(persistedRecipe.ingredientObjects.orEmpty.count == 1)
        #expect(currentIngredient.value == "Pepper")
        #expect(removedIngredient.recipes.orEmpty.isEmpty)
        #expect(removedIngredient.objects.orEmpty.count == 1)
        #expect(removedIngredientObject.recipe == nil)
    }

    @Test
    func update_diary_replaces_old_diary_objects() throws {
        let context = makeTestContext()
        let firstRecipe = makeAuditRecipe(
            context: context,
            name: "Breakfast",
            photos: [],
            ingredients: [],
            categories: []
        )
        let secondRecipe = makeAuditRecipe(
            context: context,
            name: "Lunch",
            photos: [],
            ingredients: [],
            categories: []
        )
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [firstRecipe],
            lunches: [],
            dinners: [],
            note: ""
        )
        try context.save()
        let removedObjectID = try #require(
            diary.objects.orEmpty.first?.persistentModelID
        )

        DiaryService.update(
            context: context,
            diary: diary,
            date: diary.date,
            breakfasts: [],
            lunches: [secondRecipe],
            dinners: [],
            note: "updated"
        )
        try context.save()

        let verificationContext = auditReloadedContext(from: context)
        let persistedDiary = try #require(
            verificationContext.fetch(.diaries(.all)).first
        )
        let diaryObjects = try verificationContext.fetch(FetchDescriptor<DiaryObject>())
        let attachedObject = try #require(
            persistedDiary.objects.orEmpty.first
        )
        let removedObject = try #require(
            diaryObjects.first { diaryObject in
                diaryObject.persistentModelID == removedObjectID
            }
        )

        #expect(diaryObjects.count == 2)
        #expect(persistedDiary.objects.orEmpty.count == 1)
        #expect(attachedObject.persistentModelID != removedObjectID)
        #expect(attachedObject.recipe?.persistentModelID == secondRecipe.persistentModelID)
        #expect(attachedObject.type == .lunch)
        #expect(removedObject.diary == nil)
    }
}

private func requirePhotoObject(
    matching data: Data,
    in photoObjects: [PhotoObject]
) throws -> PhotoObject {
    try #require(
        photoObjects.first { photoObject in
            photoObject.photo?.data == data
        }
    )
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

private func requireIngredientObject(
    named value: String,
    in ingredientObjects: [IngredientObject]
) throws -> IngredientObject {
    try #require(
        ingredientObjects.first { ingredientObject in
            ingredientObject.ingredient?.value == value
        }
    )
}
