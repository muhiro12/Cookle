@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct RecipePredicateTests {
    let context: ModelContext = makeTestContext()

    @Test("anyTextMatches short text equals ingredient/category")
    func anyTextMatches_shortText_matchesIngredientsAndCategories() throws {
        let breakfast = Category.create(context: context, value: "Breakfast")

        _ = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [.create(context: context, ingredient: "Egg", amount: "2", order: 1)],
            steps: [],
            categories: [breakfast],
            note: ""
        )

        // short text (<3) should use equality for tags
        let byIngredient = try context.fetch(.recipes(.anyTextMatches("Egg")))
        #expect(byIngredient.count == 1)

        let byCategory = try context.fetch(.recipes(.anyTextMatches("Breakfast")))
        #expect(byCategory.count == 1)
    }

    @Test("anyTextMatches long text contains in name")
    func anyTextMatches_longText_matchesNameContains() throws {
        _ = Recipe.create(
            context: context,
            name: "Spaghetti Bolognese",
            photos: [],
            servingSize: 2,
            cookingTime: 30,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try context.fetch(.recipes(.anyTextMatches("Bologn")))
        #expect(result.first?.name == "Spaghetti Bolognese")
    }
}
