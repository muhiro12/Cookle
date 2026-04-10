import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct RecipeSaveLoggingTests {
    @Test
    func makeSummary_classifies_existing_and_new_tags_by_exact_match() throws {
        let context = try makeCookleTestContext()
        _ = Ingredient.create(
            context: context,
            value: "Salt"
        )
        _ = Category.create(
            context: context,
            value: "Dinner"
        )
        try context.save()
        let draft = try RecipeFormService.makeDraft(
            name: "Soup",
            photos: [],
            servingSize: "2",
            cookingTime: "15",
            ingredients: [
                .init(ingredient: "Salt", amount: "1 tsp"),
                .init(ingredient: "Pepper", amount: "1 tsp"),
                .init(ingredient: "Pepper", amount: "2 tsp")
            ],
            steps: [
                "Mix"
            ],
            categories: [
                "Dinner",
                "Quick",
                "Quick"
            ],
            note: ""
        )

        let summary = RecipeSaveLogging.makeSummary(
            operation: "create",
            context: context,
            draft: draft
        )

        #expect(summary.operation == "create")
        #expect(summary.reusedIngredientValues == ["Salt"])
        #expect(summary.createdIngredientValues == ["Pepper"])
        #expect(summary.reusedCategoryValues == ["Dinner"])
        #expect(summary.createdCategoryValues == ["Quick"])
    }
}
