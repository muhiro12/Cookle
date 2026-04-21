@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct TagServiceTests {
    let context: ModelContext = makeTestContext()

    private func makeBreakfastRecipe(
        name: String,
        amount: String
    ) -> Recipe {
        let ingredients = [
            IngredientObject.create(
                context: context,
                ingredient: "Eggs",
                amount: amount,
                order: 1
            )
        ]
        let categories = [
            Category.create(
                context: context,
                value: "Breakfast"
            )
        ]
        return .create(
            context: context,
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: ingredients,
            steps: [
                "Cook the eggs."
            ],
            categories: categories,
            note: ""
        )
    }

    @Test
    func ingredient_create_reuses_existing_value() throws {
        let firstIngredient = Ingredient.create(
            context: context,
            value: "Eggs"
        )
        let secondIngredient = Ingredient.create(
            context: context,
            value: "Eggs"
        )

        let ingredients = try context.fetch(.ingredients(.all))

        #expect(firstIngredient.persistentModelID == secondIngredient.persistentModelID)
        #expect(ingredients.count == 1)
    }

    @Test
    func category_create_reuses_existing_value() throws {
        let firstCategory = Category.create(
            context: context,
            value: "Breakfast"
        )
        let secondCategory = Category.create(
            context: context,
            value: "Breakfast"
        )

        let categories = try context.fetch(.categories(.all))

        #expect(firstCategory.persistentModelID == secondCategory.persistentModelID)
        #expect(categories.count == 1)
    }

    @Test
    func ingredient_descriptor_matches_exact_and_kana_variants() throws {
        _ = Ingredient.create(
            context: context,
            value: "Salt"
        )
        _ = Ingredient.create(
            context: context,
            value: "タマネギ"
        )

        let exactMatches = try context.fetch(.ingredients(.valueContains("Salt")))
        let kanaMatches = try context.fetch(.ingredients(.valueContains("たま")))

        #expect(exactMatches.map(\.value) == ["Salt"])
        #expect(kanaMatches.map(\.value) == ["タマネギ"])
    }

    @Test
    func category_descriptor_matches_exact_and_kana_variants() throws {
        _ = Category.create(
            context: context,
            value: "Breakfast"
        )
        _ = Category.create(
            context: context,
            value: "アジア"
        )

        let exactMatches = try context.fetch(.categories(.valueContains("Breakfast")))
        let kanaMatches = try context.fetch(.categories(.valueContains("あじ")))

        #expect(exactMatches.map(\.value) == ["Breakfast"])
        #expect(kanaMatches.map(\.value) == ["アジア"])
    }

    @Test
    func preview_style_recipe_creation_reuses_existing_tags() throws {
        _ = makeBreakfastRecipe(
            name: "Omelette",
            amount: "2"
        )
        _ = makeBreakfastRecipe(
            name: "Scrambled Eggs",
            amount: "3"
        )

        let ingredients = try context.fetch(.ingredients(.valueIs("Eggs")))
        let categories = try context.fetch(.categories(.valueIs("Breakfast")))

        #expect(ingredients.count == 1)
        #expect(categories.count == 1)
    }

    @Test
    func rename_updates_ingredient_value() throws {
        let ingredient = Ingredient.create(
            context: context,
            value: "Egg"
        )

        try TagService.rename(
            context: context,
            ingredient: ingredient,
            value: "Eggs"
        )

        #expect(ingredient.value == "Eggs")
    }

    @Test
    func rename_updates_category_value() throws {
        let category = Category.create(
            context: context,
            value: "Lunch"
        )

        try TagService.rename(
            context: context,
            category: category,
            value: "Dinner"
        )

        #expect(category.value == "Dinner")
    }

    @Test
    func delete_category_removes_recipe_relation_but_keeps_recipe() throws {
        _ = makeBreakfastRecipe(
            name: "Omelette",
            amount: "2"
        )
        let category = try #require(
            context.fetch(.categories(.valueIs("Breakfast"))).first
        )

        let outcome = TagService.deleteWithOutcome(
            context: context,
            category: category
        )
        try context.save()

        #expect(outcome.effects == [.notificationPlanChanged])
        #expect(try context.fetchCount(FetchDescriptor<Category>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 1)
        let recipe = try #require(
            context.fetch(.recipes(.all)).first
        )
        #expect(recipe.categories.orEmpty.isEmpty)
    }

    @Test
    func delete_unused_ingredient_removes_only_the_root_record() throws {
        let ingredient = Ingredient.create(
            context: context,
            value: "Paprika"
        )

        let outcome = try TagService.deleteWithOutcome(
            context: context,
            ingredient: ingredient
        )
        try context.save()

        #expect(outcome.effects == [.notificationPlanChanged])
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<IngredientObject>()) == 0)
    }

    @Test
    func delete_in_use_ingredient_is_rejected() throws {
        _ = makeBreakfastRecipe(
            name: "Omelette",
            amount: "2"
        )
        let ingredient = try #require(
            context.fetch(.ingredients(.valueIs("Eggs"))).first
        )

        #expect(throws: TagServiceError.ingredientInUse("Eggs")) {
            try TagService.deleteWithOutcome(
                context: context,
                ingredient: ingredient
            )
        }
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<IngredientObject>()) == 1)
    }
}
