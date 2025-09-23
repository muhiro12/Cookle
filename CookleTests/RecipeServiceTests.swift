@testable import Cookle
import SwiftData
import SwiftUI
import Testing

@MainActor
struct RecipeServiceTests {
    let context: ModelContext = testContext

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
        AppStorage(.lastOpenedRecipeID).wrappedValue = encoded

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
}
