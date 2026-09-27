@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecentRecipeCatalogTests {
    private static func recipe(
        _ recipeID: String,
        steps: [String] = ["Step"]
    ) -> RecentRecipe {
        .init(
            recipeID: recipeID,
            title: recipeID,
            steps: steps,
            updatedAt: .init(timeIntervalSinceReferenceDate: 1)
        )
    }

    @Test
    func history_moves_reopened_recipes_to_the_front_without_duplicates() {
        var history = RecentRecipeHistory()
        for recipeID in ["a", "b", "c", "a"] {
            history.recordOpened(recipeID)
        }

        #expect(history.recipeIDs == ["a", "c", "b"])

        for index in 0..<20 {
            history.recordOpened("r\(index)")
        }
        #expect(history.recipeIDs.count == RecentRecipeHistory.maximumStoredCount)
    }

    @Test
    func catalog_bounds_count_and_skips_duplicates_and_empty_recipes() {
        let catalog = RecentRecipeCatalog.bounded(
            [
                Self.recipe("a"),
                Self.recipe("a"),
                Self.recipe("empty", steps: []),
                Self.recipe("b"),
                Self.recipe("c"),
                Self.recipe("d"),
                Self.recipe("e"),
                Self.recipe("f")
            ],
            generatedAt: .init(timeIntervalSinceReferenceDate: 2)
        )

        #expect(catalog.recipes.map(\.recipeID) == ["a", "b", "c", "d", "e"])
    }

    @Test
    func oversized_recipe_is_omitted_rather_than_truncated() {
        let hugeStep = String(repeating: "x", count: RecentRecipeCatalog.maximumEncodedByteCount)
        let catalog = RecentRecipeCatalog.bounded(
            [Self.recipe("huge", steps: [hugeStep]), Self.recipe("small")],
            generatedAt: .init(timeIntervalSinceReferenceDate: 2)
        )

        #expect(catalog.recipes.map(\.recipeID) == ["small"])
        #expect((catalog.encodedString()?.utf8.count ?? .max) <= RecentRecipeCatalog.maximumEncodedByteCount)
    }

    @Test
    func malformed_unsupported_and_oversized_payloads_are_rejected() {
        #expect(RecentRecipeCatalog.decoded(from: "nope") == nil)
        #expect(RecentRecipeCatalog.decoded(from: #"{"formatVersion":99,"recipes":[],"generatedAt":0}"#) == nil)
        #expect(RecentRecipeCatalog.decoded(from: String(repeating: " ", count: 30_000)) == nil)

        let empty = RecentRecipeCatalog(recipes: [], generatedAt: .init(timeIntervalSinceReferenceDate: 0))
        #expect(RecentRecipeCatalog.decoded(from: empty.encodedString() ?? "") == empty)
    }

    @Test
    func catalog_reflects_edits_and_drops_deleted_recipes() throws {
        let context = makeTestContext()
        let kept = Recipe.create(
            context: context,
            content: .init(name: "Kept", steps: ["Boil"])
        )
        let deleted = Recipe.create(
            context: context,
            content: .init(name: "Deleted", steps: ["Fry"])
        )
        let stepless = Recipe.create(
            context: context,
            content: .init(name: "Stepless", steps: [])
        )
        try context.save()
        var history = RecentRecipeHistory()
        for recipe in [kept, deleted, stepless] {
            history.recordOpened(CookingSessionOperations.recentRecipeID(for: recipe))
        }

        context.delete(deleted)
        try context.save()
        let result = try CookingSessionOperations.recentRecipeCatalog(
            history: history,
            context: context
        )

        #expect(result.catalog.recipes.map(\.title) == ["Kept"])
        #expect(result.history.recipeIDs.count == 2)
    }

    @Test
    func starting_from_a_cached_recipe_is_explicit_and_fresh() {
        let snapshot = Self.recipe("a").startingSnapshot(startedAt: .init(timeIntervalSinceReferenceDate: 5))

        #expect(snapshot.isActive)
        #expect(snapshot.currentStepIndex == 0)
        #expect(snapshot.activeTimer == nil)
    }

    @Test
    func received_duplicate_identifiers_and_empty_steps_are_rejected() throws {
        let recipe = RecentRecipe(recipeID: "one", title: "Soup", steps: ["Cook"], updatedAt: .now)
        let duplicate = RecentRecipeCatalog(recipes: [recipe, recipe], generatedAt: .now)
        #expect(RecentRecipeCatalog.decoded(from: try #require(duplicate.encodedString())) == nil)
        let empty = RecentRecipeCatalog(recipes: [.init(recipeID: "two", title: "Soup", steps: [], updatedAt: .now)],
                                        generatedAt: .now)
        #expect(RecentRecipeCatalog.decoded(from: try #require(empty.encodedString())) == nil)
    }
}
