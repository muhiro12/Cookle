@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipeWebsitePersistenceTests {
    @Test
    func reviewed_source_survives_save_and_reopening_without_remote_photos() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("recipes.sqlite")
        let sourceURL = try #require(URL(string: "https://recipes.example/soup"))
        let source = try RecipeWebsiteImportOperations.source(
            structuredData: [#"""
                {"@type":"Recipe","name":"Soup","recipeIngredient":["Water 200ml"],
                "recipeInstructions":["Boil water.","Select mode 2 → Start."],
                "recipeYield":"2 servings","cookTime":"PT5M","author":"Example author"}
            """#],
            visibleText: "",
            sourceNotes: ["Keep refrigerated."]
        )
        let inferred = source.grounding(.init(
            name: "Soup",
            servingSize: 0,
            cookingTime: 0,
            ingredients: [.init(ingredient: "Water", amount: "200ml")],
            steps: [],
            categories: [],
            note: ""
        ))
        let note = RecipeWebsiteImportOperations.note(inferred.note, sourceURL: sourceURL)
        let draft = try RecipeFormOperations.makeDraft(input: .init(
            name: "Reviewed soup",
            photos: [],
            servingSize: inferred.servingSize.description,
            cookingTime: inferred.cookingTime.description,
            ingredients: inferred.ingredients.map { .init(ingredient: $0.ingredient, amount: $0.amount) },
            steps: inferred.steps,
            categories: [],
            note: note
        ))
        try save(draft, at: storeURL)
        let container = try ModelContainerFactory.makeModelContainer(url: storeURL, cloudKitDatabase: .none)
        let context = ModelContext(container)
        let recipe = try #require(context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(recipe.name == "Reviewed soup")
        #expect(recipe.note == note)
        #expect(recipe.note.contains(sourceURL.absoluteString))
        #expect(recipe.note.contains("Example author"))
        #expect(recipe.note.contains("Keep refrigerated."))
        #expect(recipe.steps == inferred.steps)
        #expect(recipe.servingSize == 2)
        #expect(recipe.cookingTime == 5)
        #expect(recipe.photoObjects?.isEmpty == true)
        #expect(recipe.ingredientObjects?.first?.amount == "200ml")
    }

    private func save(_ draft: RecipeFormDraft, at url: URL) throws {
        let container = try ModelContainerFactory.makeModelContainer(url: url, cloudKitDatabase: .none)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 0)
        _ = try RecipeFormOperations.createWithOutcome(context: context, draft: draft)
        try context.save()
    }
}
