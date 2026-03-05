@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct RecipeStableIdentifierCodecTests {
    let context: ModelContext = makeTestContext()

    @Test
    func encode_and_decode_round_trip_recipe_identifier() throws {
        let recipe = Recipe.create(
            context: context,
            name: "Soup",
            photos: [],
            servingSize: 2,
            cookingTime: 20,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let encodedIdentifier = try RecipeStableIdentifierCodec.encode(
            recipe.id
        )
        let decodedIdentifier = try RecipeStableIdentifierCodec.decode(
            encodedIdentifier
        )

        #expect(decodedIdentifier == recipe.id)
    }

    @Test
    func recipe_lookup_resolves_existing_recipe() throws {
        let recipe = Recipe.create(
            context: context,
            name: "Curry",
            photos: [],
            servingSize: 3,
            cookingTime: 30,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
        let resolvedRecipe = try RecipeStableIdentifierCodec.recipe(
            from: stableIdentifier,
            context: context
        )

        #expect(resolvedRecipe === recipe)
    }

    @Test
    func recipe_lookup_returns_nil_for_invalid_identifier() throws {
        let resolvedRecipe = try RecipeStableIdentifierCodec.recipe(
            from: "invalid-id",
            context: context
        )
        #expect(resolvedRecipe == nil)
    }
}
