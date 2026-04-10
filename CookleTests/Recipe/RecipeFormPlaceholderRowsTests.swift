import Testing

@testable import Cookle

@MainActor
struct RecipeFormPlaceholderRowsTests {
    @Test
    func normalizedStrings_appendsTrailingPlaceholderAfterContent() {
        let result = RecipeFormPlaceholderRows.normalizedStrings(
            ["Boil water"]
        )

        #expect(result == ["Boil water", ""])
    }

    @Test
    func normalizedStrings_collapsesOnlyTrailingPlaceholders() {
        let result = RecipeFormPlaceholderRows.normalizedStrings(
            ["", "Cook pasta", "", ""]
        )

        #expect(result == ["", "Cook pasta", ""])
    }

    @Test
    func normalizedIngredients_keepsInteriorEmptyRowAndSingleTrailingPlaceholder() {
        let result = RecipeFormPlaceholderRows.normalizedIngredients(
            [
                .init(
                    ingredient: "Salt",
                    amount: "1 tsp"
                ),
                .init(
                    ingredient: "",
                    amount: ""
                ),
                .init(
                    ingredient: "Pepper",
                    amount: ""
                ),
                .init(
                    ingredient: "",
                    amount: ""
                ),
                .init(
                    ingredient: "",
                    amount: ""
                )
            ]
        )

        #expect(result.count == 4)
        #expect(result[0].ingredient == "Salt")
        #expect(result[1].ingredient.isEmpty)
        #expect(result[2].ingredient == "Pepper")
        #expect(result[3].ingredient.isEmpty)
        #expect(result[3].amount.isEmpty)
    }

    @Test
    func normalizedIngredients_restoresPlaceholderWhenArrayBecomesEmpty() {
        let result = RecipeFormPlaceholderRows.normalizedIngredients([])

        #expect(result.count == 1)
        #expect(result[0].ingredient.isEmpty)
        #expect(result[0].amount.isEmpty)
    }
}
