@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipeServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func search_returns_recipes_matching_prefix() throws {
        _ = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = Recipe.create(
            context: context,
            name: "Spaghetti",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try RecipeService.search(
            context: context,
            text: "Panc"
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }

    @Test
    func lastOpenedRecipe_returns_recipe_from_storage() throws {
        let recipe = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let encoded = try recipe.id.base64Encoded()
        CooklePreferences.set(encoded, for: .lastOpenedRecipeID)

        let result = try RecipeService.lastOpenedRecipe(context: context)
        #expect(result === recipe)
    }

    @Test
    func randomRecipe_returns_any_existing_recipe() throws {
        let pancake = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = Recipe.create(
            context: context,
            name: "Spaghetti",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try RecipeService.randomRecipe(context: context)
        #expect(result != nil)
        #expect(result === pancake || result?.name == "Spaghetti")
    }

    @Test
    func latestRecipe_returns_nil_when_store_is_empty() throws {
        let result = try RecipeService.latestRecipe(context: context)
        #expect(result == nil)
    }

    @Test
    func randomRecipe_returns_nil_when_store_is_empty() throws {
        let result = try RecipeService.randomRecipe(context: context)
        #expect(result == nil)
    }

    @Test
    func latestRecipe_prefers_recently_updated_recipe_over_newer_created_recipe() throws {
        let firstRecipe = Recipe.create(
            context: context,
            name: "First",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        Thread.sleep(forTimeInterval: 0.001)
        let secondRecipe = Recipe.create(
            context: context,
            name: "Second",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        firstRecipe.update(
            name: firstRecipe.name,
            photos: [],
            servingSize: firstRecipe.servingSize,
            cookingTime: firstRecipe.cookingTime,
            ingredients: [],
            steps: firstRecipe.steps,
            categories: [],
            note: firstRecipe.note
        )

        let result = try RecipeService.latestRecipe(context: context)
        #expect(result === firstRecipe)
        #expect(result !== secondRecipe)
    }

    @Test
    func latestRecipe_prefers_newer_created_when_not_updated() throws {
        let firstRecipe = Recipe.create(
            context: context,
            name: "First",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        Thread.sleep(forTimeInterval: 0.001)
        let secondRecipe = Recipe.create(
            context: context,
            name: "Second",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try RecipeService.latestRecipe(context: context)
        #expect(result === secondRecipe)
        #expect(result !== firstRecipe)
    }
}
