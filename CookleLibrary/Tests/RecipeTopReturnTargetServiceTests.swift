@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct RecipeTopReturnTargetServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func activeSession_is_preferred_over_lastOpenedRecipe() throws {
        let lastOpenedRecipe = makeRecipe(
            name: "Toast"
        )
        let lastOpenedRecipeID = RecipeStableIdentifierCodec.stableIdentifier(
            for: lastOpenedRecipe
        )
        let activeSnapshot = makeSnapshot(
            recipeID: "active-recipe-id",
            recipeName: "Pasta",
            steps: ["Boil water"]
        )

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: activeSnapshot.encodedString(),
            lastOpenedRecipeID: lastOpenedRecipeID
        )

        #expect(
            result == .init(
                kind: .activeCookingSession,
                recipeName: "Pasta",
                recipeStableIdentifier: "active-recipe-id"
            )
        )
    }

    @Test
    func inactiveSession_falls_back_to_lastOpenedRecipe() throws {
        let recipe = makeRecipe(
            name: "Soup"
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
        let inactiveSnapshot = makeSnapshot(
            recipeID: "inactive-recipe-id",
            recipeName: "Old Session",
            steps: ["Wait"],
            isActive: false
        )

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: inactiveSnapshot.encodedString(),
            lastOpenedRecipeID: stableIdentifier
        )

        #expect(
            result == .init(
                kind: .lastOpenedRecipe,
                recipeName: "Soup",
                recipeStableIdentifier: stableIdentifier
            )
        )
    }

    @Test
    func malformedSnapshot_falls_back_to_lastOpenedRecipe() throws {
        let recipe = makeRecipe(
            name: "Curry"
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: "not-json",
            lastOpenedRecipeID: stableIdentifier
        )

        #expect(
            result == .init(
                kind: .lastOpenedRecipe,
                recipeName: "Curry",
                recipeStableIdentifier: stableIdentifier
            )
        )
    }

    @Test
    func emptyStepSnapshot_is_treated_as_invalid() throws {
        let activeSnapshot = makeSnapshot(
            recipeID: "empty-steps",
            recipeName: "Empty Steps",
            steps: []
        )

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: activeSnapshot.encodedString(),
            lastOpenedRecipeID: nil
        )

        #expect(result == nil)
    }

    @Test
    func missingLastOpenedRecipe_returns_nil() throws {
        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: nil,
            lastOpenedRecipeID: nil
        )

        #expect(result == nil)
    }

    @Test
    func deletedLastOpenedRecipe_returns_nil() throws {
        let recipe = makeRecipe(
            name: "Deleted"
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        context.delete(recipe)

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: nil,
            lastOpenedRecipeID: stableIdentifier
        )

        #expect(result == nil)
    }

    @Test
    func activeSession_keeps_target_when_recipe_record_is_deleted() throws {
        let recipe = makeRecipe(
            name: "Deleted Session Recipe"
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
        let activeSnapshot = makeSnapshot(
            recipeID: stableIdentifier,
            recipeName: recipe.name,
            steps: ["Cook"]
        )

        context.delete(recipe)

        let result = try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: activeSnapshot.encodedString(),
            lastOpenedRecipeID: nil
        )

        #expect(
            result == .init(
                kind: .activeCookingSession,
                recipeName: "Deleted Session Recipe",
                recipeStableIdentifier: stableIdentifier
            )
        )
    }
}

private extension RecipeTopReturnTargetServiceTests {
    enum TestValues {
        static let cookingTimeMinutes = 10
    }

    func makeRecipe(
        name: String
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: TestValues.cookingTimeMinutes,
            ingredients: [],
            steps: ["Cook"],
            categories: [],
            note: ""
        )
    }

    func makeSnapshot(
        recipeID: String,
        recipeName: String,
        steps: [String],
        isActive: Bool = true
    ) -> CookingSessionSnapshot {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: .zero,
            activeTimer: nil,
            updatedAt: .now,
            isActive: isActive
        )
    }
}
