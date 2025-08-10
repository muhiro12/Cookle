@testable import Cookle
import SwiftData
import Testing

@MainActor
struct SearchServiceTests {
    let context: ModelContext = testContext

    @Test
    func search_returns_recipes_matching_text_in_ingredients_or_categories() throws {
        _ = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [
                .create(context: context, ingredient: "Egg", amount: "2", order: 1)
            ],
            steps: [],
            categories: [],
            note: ""
        )
        let category = Category.create(context: context, value: "Breakfast")
        _ = Recipe.create(
            context: context,
            name: "Toast",
            photos: [],
            servingSize: 1,
            cookingTime: 5,
            ingredients: [],
            steps: [],
            categories: [category],
            note: ""
        )

        let result = try SearchService.search(
            context: context,
            text: "Egg"
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }
}
