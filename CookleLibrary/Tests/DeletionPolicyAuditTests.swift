@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("DeletionPolicyAudit")
struct DeletionPolicyAuditTests {
    @Test
    func delete_recipe_cascades_subobjects_but_keeps_photo_and_ingredient_records() throws {
        let context = makeTestContext()
        let sharedPhotoData = makePhotoData("shared")
        let uniquePhotoData = makePhotoData("unique")

        let recipe = makeRecipe(
            context: context,
            name: "Delete Target",
            photos: [sharedPhotoData, uniquePhotoData],
            ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
            categories: []
        )
        let remainingRecipe = makeRecipe(
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
        let orphanedPhoto = try #require(
            photos.first { photo in
                photo.data == uniquePhotoData.data
            }
        )
        let sharedPhoto = try #require(
            photos.first { photo in
                photo.data == sharedPhotoData.data
            }
        )

        #expect(try count(of: Recipe.self, in: context) == 1)
        #expect(try count(of: PhotoObject.self, in: context) == 1)
        #expect(try count(of: IngredientObject.self, in: context) == 0)
        #expect(try count(of: DiaryObject.self, in: context) == 0)
        #expect(try count(of: Photo.self, in: context) == 2)
        #expect(try count(of: Ingredient.self, in: context) == 1)
        #expect(try count(of: Diary.self, in: context) == 1)
        #expect(remainingRecipe.orderedPhotos.count == 1)
        #expect(diary.objects.orEmpty.isEmpty)
        #expect(orphanedPhoto.recipes.orEmpty.isEmpty)
        #expect(orphanedPhoto.objects.orEmpty.isEmpty)
        #expect(sharedPhoto.recipes.orEmpty.count == 1)
    }

    @Test
    func update_recipe_replaces_photo_objects_but_leaves_removed_photo_asset_orphaned() throws {
        let context = makeTestContext()
        let firstPhotoData = makePhotoData("first")
        let secondPhotoData = makePhotoData("second")
        let recipe = makeRecipe(
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
            draft: .init(
                name: "Photo Update",
                photos: [secondPhotoData],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()

        let verificationContext = reloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentPhoto = try #require(persistedRecipe.orderedPhotos.first)
        let photoObjects = try verificationContext.fetch(FetchDescriptor<PhotoObject>())
        let removedPhoto = try #require(
            verificationContext.fetch(.photos(.all)).first { photo in
                photo.data == firstPhotoData.data
            }
        )
        let removedPhotoObject = try #require(
            photoObjects.first { photoObject in
                photoObject.photo?.data == firstPhotoData.data
            }
        )

        #expect(photoObjects.count == 2)
        #expect(try count(of: Photo.self, in: verificationContext) == 2)
        #expect(persistedRecipe.orderedPhotoObjects.count == 1)
        #expect(currentPhoto.data == secondPhotoData.data)
        #expect(removedPhoto.recipes.orEmpty.isEmpty)
        #expect(removedPhoto.objects.orEmpty.count == 1)
        #expect(removedPhotoObject.recipe == nil)
    }

    @Test
    func update_recipe_replaces_ingredient_objects_but_leaves_removed_ingredient_orphaned() throws {
        let context = makeTestContext()
        let recipe = makeRecipe(
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
            draft: .init(
                name: "Ingredient Update",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [.init(ingredient: "Pepper", amount: "1 tsp")],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()

        let verificationContext = reloadedContext(from: context)
        let persistedRecipe = try #require(
            verificationContext.fetch(.recipes(.all)).first
        )
        let currentIngredient = try #require(
            persistedRecipe.ingredientObjects.orEmpty.first?.ingredient
        )
        let ingredientObjects = try verificationContext.fetch(
            FetchDescriptor<IngredientObject>()
        )
        let removedIngredient = try #require(
            verificationContext.fetch(.ingredients(.all)).first { ingredient in
                ingredient.value == "Salt"
            }
        )
        let removedIngredientObject = try #require(
            ingredientObjects.first { ingredientObject in
                ingredientObject.ingredient?.value == "Salt"
            }
        )

        #expect(ingredientObjects.count == 2)
        #expect(try count(of: Ingredient.self, in: verificationContext) == 2)
        #expect(persistedRecipe.ingredientObjects.orEmpty.count == 1)
        #expect(currentIngredient.value == "Pepper")
        #expect(removedIngredient.recipes.orEmpty.isEmpty)
        #expect(removedIngredient.objects.orEmpty.count == 1)
        #expect(removedIngredientObject.recipe == nil)
    }

    @Test
    func update_diary_replaces_old_diary_objects() throws {
        let context = makeTestContext()
        let firstRecipe = makeRecipe(
            context: context,
            name: "Breakfast",
            photos: [],
            ingredients: [],
            categories: []
        )
        let secondRecipe = makeRecipe(
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

        let verificationContext = reloadedContext(from: context)
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

    @Test
    func delete_in_use_category_keeps_recipe_and_drops_relationship() throws {
        let context = makeTestContext()
        let recipe = makeRecipe(
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

        #expect(try count(of: Category.self, in: context) == 0)
        #expect(try count(of: Recipe.self, in: context) == 1)
        #expect(persistedRecipe.categories.orEmpty.isEmpty)
    }

    @Test
    func data_reset_removes_every_persisted_model() throws {
        let context = makeTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Reset Target",
            photos: [makePhotoData("reset")],
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

        let counts = try modelCounts(
            context: reloadedContext(from: context)
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

private extension DeletionPolicyAuditTests {
    struct IngredientInput {
        let ingredient: String
        let amount: String
    }

    struct ModelCounts {
        let recipeCount: Int
        let diaryCount: Int
        let photoCount: Int
        let categoryCount: Int
        let ingredientCount: Int
        let diaryObjectCount: Int
        let photoObjectCount: Int
        let ingredientObjectCount: Int
    }

    func makePhotoData(
        _ identifier: String
    ) -> PhotoData {
        .init(
            data: Data(identifier.utf8),
            source: .photosPicker
        )
    }

    func makeRecipe(
        context: ModelContext,
        name: String,
        photos: [PhotoData],
        ingredients: [IngredientInput],
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
            servingSize: 1,
            cookingTime: 10,
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

    func count<Model: PersistentModel>(
        of _: Model.Type,
        in context: ModelContext
    ) throws -> Int {
        try context.fetchCount(FetchDescriptor<Model>())
    }

    func modelCounts(
        context: ModelContext
    ) throws -> ModelCounts {
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

    func reloadedContext(
        from context: ModelContext
    ) -> ModelContext {
        .init(context.container)
    }
}
