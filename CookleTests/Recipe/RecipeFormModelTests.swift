import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct RecipeFormModelTests {
    @Test
    func applyRecipeIfNeeded_populatesFormStateOnce() throws {
        let context = try makeCookleTestContext()
        let recipe = Recipe.create(
            context: context,
            name: "Pasta",
            photos: [],
            servingSize: 2,
            cookingTime: 15,
            ingredients: [
                IngredientObject.create(
                    context: context,
                    ingredient: "Spaghetti",
                    amount: "100g",
                    order: 1
                )
            ],
            steps: ["Boil water", "Cook pasta"],
            categories: [
                Category.create(
                    context: context,
                    value: "Dinner"
                )
            ],
            note: "Classic"
        )
        let model = RecipeFormModel(
            type: .edit
        )

        model.applyRecipeIfNeeded(
            recipe
        )

        #expect(model.name == "Pasta")
        #expect(model.servingSize == "2")
        #expect(model.cookingTime == "15")
        #expect(model.ingredients.first?.ingredient == "Spaghetti")
        #expect(Array(model.steps.prefix(2)) == ["Boil water", "Cook pasta"])
        #expect(model.categories.first == "Dinner")
        #expect(model.note == "Classic")

        model.name = "Changed"
        model.applyRecipeIfNeeded(
            recipe
        )

        #expect(model.name == "Changed")
    }
}
