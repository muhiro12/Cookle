@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct TagPredicateTests {
    let context: ModelContext = makeTestContext()

    @Test
    func idIs_resolves_category_by_persistent_identifier() throws {
        let breakfast = Category.create(
            context: context,
            value: "Breakfast"
        )
        _ = Category.create(
            context: context,
            value: "Dinner"
        )

        let categories = try context.fetch(
            .categories(.idIs(breakfast.persistentModelID))
        )

        #expect(categories.map(\.value) == ["Breakfast"])
    }

    @Test
    func idIs_resolves_ingredient_by_persistent_identifier() throws {
        let egg = Ingredient.create(
            context: context,
            value: "Egg"
        )
        _ = Ingredient.create(
            context: context,
            value: "Salt"
        )

        let ingredients = try context.fetch(
            .ingredients(.idIs(egg.persistentModelID))
        )

        #expect(ingredients.map(\.value) == ["Egg"])
    }
}
