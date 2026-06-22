@testable import CookleLibrary
import Foundation
import MHPlatformCore
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct RecipeServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func search_returns_recipes_matching_prefix() throws {
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Spaghetti",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        let result = try RecipeService.search(
            context: context,
            text: "Panc"
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }

    @Test
    func randomRecipe_returns_any_existing_recipe() throws {
        let pancake = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Spaghetti",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
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
            content: .init(
                name: "First",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        Thread.sleep(forTimeInterval: 0.001)
        let secondRecipe = Recipe.create(
            context: context,
            content: .init(
                name: "Second",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        firstRecipe.update(
            content: .init(
                name: firstRecipe.name,
                photos: [],
                servingSize: firstRecipe.servingSize,
                cookingTime: firstRecipe.cookingTime,
                ingredients: [],
                steps: firstRecipe.steps,
                categories: [],
                note: firstRecipe.note
            )
        )

        let result = try RecipeService.latestRecipe(context: context)
        #expect(result === firstRecipe)
        #expect(result !== secondRecipe)
    }

    @Test
    func latestRecipe_prefers_newer_created_when_not_updated() throws {
        let firstRecipe = Recipe.create(
            context: context,
            content: .init(
                name: "First",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        Thread.sleep(forTimeInterval: 0.001)
        let secondRecipe = Recipe.create(
            context: context,
            content: .init(
                name: "Second",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        let result = try RecipeService.latestRecipe(context: context)
        #expect(result === secondRecipe)
        #expect(result !== firstRecipe)
    }

    @Test
    func delete_removes_recipe_from_store() throws {
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        RecipeService.delete(
            context: context,
            recipe: recipe
        )

        let result = try context.fetch(.recipes(.all))
        #expect(result.isEmpty)
    }
}

extension RecipeServiceTests {
    @Test
    func lastOpenedRecipe_returns_recipe_from_storage() throws {
        let preferenceKey = MHPreferenceDescriptors().lastOpenedRecipeID.storageKey
        let sharedDefaults = makeSharedUserDefaults()
        let standardDefaults = UserDefaults.standard
        let originalSharedValue = sharedDefaults.string(
            forKey: preferenceKey
        )
        let originalStandardValue = standardDefaults.string(
            forKey: preferenceKey
        )
        defer {
            restoreLastOpenedRecipePreference(
                sharedValue: originalSharedValue,
                standardValue: originalStandardValue
            )
        }

        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Pancakes",
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        RecipeService.recordLastOpenedRecipe(recipe)

        let result = try RecipeService.lastOpenedRecipe(context: context)
        #expect(result === recipe)
    }

    @Test
    func recordLastOpenedRecipe_stores_shared_preference() {
        let preferenceKey = MHPreferenceDescriptors().lastOpenedRecipeID.storageKey
        let sharedDefaults = makeSharedUserDefaults()
        let standardDefaults = UserDefaults.standard
        let originalSharedValue = sharedDefaults.string(
            forKey: preferenceKey
        )
        let originalStandardValue = standardDefaults.string(
            forKey: preferenceKey
        )
        defer {
            restoreLastOpenedRecipePreference(
                sharedValue: originalSharedValue,
                standardValue: originalStandardValue
            )
        }

        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Toast",
                photos: [],
                servingSize: 1,
                cookingTime: 5,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        RecipeService.recordLastOpenedRecipe(recipe)

        let sharedStoredIdentifier = sharedDefaults.string(
            forKey: preferenceKey
        )
        #expect(sharedStoredIdentifier != nil)
        #expect(sharedStoredIdentifier == CookleSharedPreferences.string(for: \.lastOpenedRecipeID))
        #expect(standardDefaults.string(forKey: preferenceKey) == originalStandardValue)
    }

    @Test
    func lastOpenedRecipe_ignores_legacy_standard_only_value() throws {
        let preferenceKey = MHPreferenceDescriptors().lastOpenedRecipeID.storageKey
        let sharedDefaults = makeSharedUserDefaults()
        let standardDefaults = UserDefaults.standard
        let originalSharedValue = sharedDefaults.string(
            forKey: preferenceKey
        )
        let originalStandardValue = standardDefaults.string(
            forKey: preferenceKey
        )
        defer {
            restoreLastOpenedRecipePreference(
                sharedValue: originalSharedValue,
                standardValue: originalStandardValue
            )
        }

        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Legacy Toast",
                photos: [],
                servingSize: 1,
                cookingTime: 5,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        sharedDefaults.removeObject(forKey: preferenceKey)
        standardDefaults.set(
            RecipeStableIdentifierCodec.encodeIfPossible(recipe.id),
            forKey: preferenceKey
        )

        let result = try RecipeService.lastOpenedRecipe(context: context)
        #expect(result == nil)
    }

    @available(iOS 26.0, *)
    @Test
    func fallbackInference_extracts_ingredients_and_steps_from_common_sections() {
        let inference = RecipeService.fallbackInference(
            from: """
            Curry Rice
            Ingredients:
            - Onion
            - Carrot
            Steps:
            1. Chop onion
            2. Simmer curry
            """
        )

        #expect(inference.name == "Curry Rice")
        #expect(inference.ingredients.map(\.ingredient) == ["Onion", "Carrot"])
        #expect(inference.steps == ["Chop onion", "Simmer curry"])
    }

    @available(iOS 26.0, *)
    @Test
    func isMeaningfulInference_returns_false_for_title_only_results() {
        let inference = RecipeInferenceResult(
            name: "Curry Rice",
            servingSize: .zero,
            cookingTime: .zero,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        #expect(RecipeService.isMeaningfulInference(inference) == false)
    }
}

private func restoreLastOpenedRecipePreference(
    sharedValue: String?,
    standardValue: String?
) {
    let key = MHPreferenceDescriptors().lastOpenedRecipeID.storageKey

    let sharedDefaults = makeSharedUserDefaults()
    if let sharedValue {
        sharedDefaults.set(sharedValue, forKey: key)
    } else {
        sharedDefaults.removeObject(forKey: key)
    }

    let standardDefaults = UserDefaults.standard
    if let standardValue {
        standardDefaults.set(standardValue, forKey: key)
    } else {
        standardDefaults.removeObject(forKey: key)
    }
}

private func makeSharedUserDefaults() -> UserDefaults {
    UserDefaults(
        suiteName: UserDefaults.appGroupIdentifier
    ) ?? .standard
}
