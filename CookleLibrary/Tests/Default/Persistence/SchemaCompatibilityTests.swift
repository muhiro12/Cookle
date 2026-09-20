@testable import CookleLibrary
import CoreData
import Foundation
import SwiftData
import Testing

@MainActor
struct SchemaCompatibilityTests {
    private enum Value {
        static let photoData = Data([1, 2, 3, 4])
        static let servingSize = 3
        static let cookingTime = 17
        static let ingredientOrder = 2
        static let photoOrder = 4
        static let diaryOrder = 3
        static let recipeCount = 2
    }

    @Test(arguments: [false, true])
    func released_store_preserves_graph_and_identity(versioned: Bool) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("default.store")
        let identifier = try seedReleasedStore(at: url, versioned: versioned)
        let before = try metadata(at: url)
        try checkCurrentStore(at: url, identifier: identifier)
        let after = try metadata(at: url)
        #expect(before[NSStoreUUIDKey] as? String == after[NSStoreUUIDKey] as? String)
        #expect(before[NSStoreModelVersionHashesKey] as? [String: Data]
                    == after[NSStoreModelVersionHashesKey] as? [String: Data])
        // Reopen after releasing the first current container and its context.
        try checkCurrentStore(at: url, identifier: identifier)
    }
}

private extension SchemaCompatibilityTests {
    func metadata(at url: URL) throws -> [String: Any] {
        try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: url,
            options: [NSReadOnlyPersistentStoreOption: true]
        )
    }

    func seedReleasedStore(at url: URL, versioned: Bool) throws -> String {
        let schema = versioned
            ? Schema(versionedSchema: ReleasedSchemaV1.self)
            : Schema(ReleasedSchemaV1.models)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: versioned ? ReleasedMigrationPlan.self : nil,
            configurations: .init(url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let ingredient = ReleasedSchemaV1.Ingredient()
        ingredient.value = "Salt"
        let category = ReleasedSchemaV1.Category()
        category.value = "Dinner"
        let photo = ReleasedSchemaV1.Photo()
        photo.data = Value.photoData
        photo.sourceID = "photos-picker"
        let recipe = ReleasedSchemaV1.Recipe()
        context.insert(recipe)
        recipe.name = "Historical recipe"
        recipe.servingSize = Value.servingSize
        recipe.cookingTime = Value.cookingTime
        recipe.steps = ["Prepare", "Cook"]
        recipe.note = "Preserve this note"
        recipe.categories = [category]
        let ingredientRow = ReleasedSchemaV1.IngredientObject()
        ingredientRow.ingredient = ingredient
        ingredientRow.amount = "1/2 tsp"
        ingredientRow.order = Value.ingredientOrder
        recipe.ingredientObjects = [ingredientRow]
        recipe.ingredients = [ingredient]
        let photoRow = ReleasedSchemaV1.PhotoObject()
        photoRow.photo = photo
        photoRow.order = Value.photoOrder
        recipe.photoObjects = [photoRow]
        recipe.photos = [photo]
        attachSharedRecipeAndDiary(
            context: context, recipe: recipe, category: category, ingredient: ingredient, photo: photo
        )
        recipe.createdTimestamp = CookleDataArchivePackageTestSupport.exportedAt
        try context.save()
        return try PersistentModelStableIdentifierCodec.encode(recipe.persistentModelID)
    }

    func attachSharedRecipeAndDiary(
        context: ModelContext,
        recipe: ReleasedSchemaV1.Recipe,
        category: ReleasedSchemaV1.Category,
        ingredient: ReleasedSchemaV1.Ingredient,
        photo: ReleasedSchemaV1.Photo
    ) {
        let secondRecipe = ReleasedSchemaV1.Recipe()
        context.insert(secondRecipe)
        secondRecipe.name = "Shared references"
        secondRecipe.categories = [category]
        secondRecipe.ingredients = [ingredient]
        secondRecipe.photos = [photo]
        let diary = ReleasedSchemaV1.Diary()
        context.insert(diary)
        diary.note = "Historical diary"
        let diaryRow = ReleasedSchemaV1.DiaryObject()
        diaryRow.recipe = recipe
        diaryRow.type = .dinner
        diaryRow.order = Value.diaryOrder
        diary.objects = [diaryRow]
        diary.recipes = [recipe]
    }

    func checkCurrentStore(at url: URL, identifier: String) throws {
        let container = try ModelContainerFactory.makeModelContainer(url: url)
        let context = ModelContext(container)
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == Value.recipeCount)
        let recipe = try #require(recipes.first { $0.name == "Historical recipe" })
        let secondRecipe = try #require(recipes.first { $0.name == "Shared references" })
        #expect(try PersistentModelStableIdentifierCodec.encode(recipe.persistentModelID) == identifier)
        #expect(recipe.servingSize == Value.servingSize)
        #expect(recipe.cookingTime == Value.cookingTime)
        #expect(recipe.steps == ["Prepare", "Cook"])
        #expect(recipe.note == "Preserve this note")
        #expect(recipe.createdTimestamp == CookleDataArchivePackageTestSupport.exportedAt)
        let ingredientRow = try #require(recipe.ingredientObjects?.first)
        #expect(ingredientRow.amount == "1/2 tsp")
        #expect(ingredientRow.order == Value.ingredientOrder)
        #expect(ingredientRow.recipe === recipe)
        #expect(ingredientRow.ingredient?.value == "Salt")
        #expect(ingredientRow.ingredient === secondRecipe.ingredients?.first)
        let photoRow = try #require(recipe.photoObjects?.first)
        #expect(photoRow.order == Value.photoOrder)
        #expect(photoRow.recipe === recipe)
        #expect(photoRow.photo?.data == Value.photoData)
        #expect(photoRow.photo?.sourceID == "photos-picker")
        #expect(photoRow.photo === secondRecipe.photos?.first)
        #expect(recipe.categories?.first?.value == "Dinner")
        #expect(recipe.categories?.first === secondRecipe.categories?.first)
        let diary = try #require(context.fetch(FetchDescriptor<Diary>()).first)
        #expect(diary.note == "Historical diary")
        #expect(diary.objects?.first?.recipe === recipe)
        #expect(diary.objects?.first?.diary === diary)
        #expect(diary.objects?.first?.type == .dinner)
        #expect(diary.objects?.first?.order == Value.diaryOrder)
        #expect(recipe.diaries?.first === diary)
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CookleLibrary.Category>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Photo>()) == 1)
    }
}
