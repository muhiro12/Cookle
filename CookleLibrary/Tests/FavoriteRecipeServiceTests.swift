@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct FavoriteRecipeServiceTests {
    @Test
    func setFavorite_marksAndUnmarksRecipe() {
        let context = makeTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Pancakes"
        )

        let encodedFavorites = FavoriteRecipeService.setFavorite(
            true,
            recipe: recipe,
            encodedFavoriteRecipeIDs: nil
        )
        #expect(
            FavoriteRecipeService.isFavorite(
                recipe,
                encodedFavoriteRecipeIDs: encodedFavorites
            )
        )

        let removedFavorites = FavoriteRecipeService.setFavorite(
            false,
            recipe: recipe,
            encodedFavoriteRecipeIDs: encodedFavorites
        )
        #expect(removedFavorites == nil)
    }

    @Test
    func favoriteRecipes_filtersRecipesByStoredIdentifiers() {
        let context = makeTestContext()
        let favoriteRecipe = makeRecipe(
            context: context,
            name: "Pancakes"
        )
        let otherRecipe = makeRecipe(
            context: context,
            name: "Toast"
        )
        let encodedFavorites = FavoriteRecipeService.setFavorite(
            true,
            recipe: favoriteRecipe,
            encodedFavoriteRecipeIDs: nil
        )

        let favoriteRecipes = FavoriteRecipeService.favoriteRecipes(
            [
                favoriteRecipe,
                otherRecipe
            ],
            encodedFavoriteRecipeIDs: encodedFavorites
        )
        let otherRecipes = FavoriteRecipeService.nonFavoriteRecipes(
            [
                favoriteRecipe,
                otherRecipe
            ],
            encodedFavoriteRecipeIDs: encodedFavorites
        )

        #expect(favoriteRecipes.map(\.name) == ["Pancakes"])
        #expect(otherRecipes.map(\.name) == ["Toast"])
    }

    @Test
    func deleteRecipe_removesRecipeFromStoredFavorites() {
        let originalFavorites = CooklePreferences.string(
            for: \.favoriteRecipeIDs
        )
        defer {
            CooklePreferences.set(
                originalFavorites,
                for: \.favoriteRecipeIDs
            )
        }

        let context = makeTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Pancakes"
        )
        CooklePreferences.set(
            FavoriteRecipeService.setFavorite(
                true,
                recipe: recipe,
                encodedFavoriteRecipeIDs: nil
            ),
            for: \.favoriteRecipeIDs
        )

        _ = RecipeService.deleteWithOutcome(
            context: context,
            recipe: recipe
        )

        #expect(
            CooklePreferences.string(
                for: \.favoriteRecipeIDs
            ) == nil
        )
    }

    @Test
    func deleteAll_removesStoredFavorites() throws {
        let originalFavorites = CooklePreferences.string(
            for: \.favoriteRecipeIDs
        )
        defer {
            CooklePreferences.set(
                originalFavorites,
                for: \.favoriteRecipeIDs
            )
        }

        let context = makeTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Pancakes"
        )
        CooklePreferences.set(
            FavoriteRecipeService.setFavorite(
                true,
                recipe: recipe,
                encodedFavoriteRecipeIDs: nil
            ),
            for: \.favoriteRecipeIDs
        )

        try DataResetService.deleteAll(
            context: context
        )

        #expect(
            CooklePreferences.string(
                for: \.favoriteRecipeIDs
            ) == nil
        )
    }
}

private extension FavoriteRecipeServiceTests {
    func makeRecipe(
        context: ModelContext,
        name: String
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }
}
