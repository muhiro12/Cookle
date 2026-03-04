@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct TagServiceTests {
    let context: ModelContext = makeTestContext()

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
    func delete_ingredient_throws_when_tag_is_used_by_recipe() throws {
        let ingredientObject = IngredientObject.create(
            context: context,
            ingredient: "Eggs",
            amount: "2",
            order: 1
        )
        let ingredient = try #require(ingredientObject.ingredient)
        _ = Recipe.create(
            context: context,
            name: "Omelette",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [ingredientObject],
            steps: [],
            categories: [],
            note: ""
        )

        #expect(
            throws: TagServiceError.ingredientInUse("Eggs")
        ) {
            try TagService.delete(
                context: context,
                ingredient: ingredient
            )
        }
    }

    @Test
    func delete_category_removes_tag_from_store() throws {
        let category = Category.create(
            context: context,
            value: "Dinner"
        )

        try TagService.delete(
            context: context,
            category: category
        )

        let categories = try context.fetch(.categories(.all))
        #expect(categories.isEmpty)
    }
}
