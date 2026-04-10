import CookleLibrary
import Testing

@testable import Cookle

@MainActor
struct RecipeDraftLoggingTests {
    @Test
    func formSummary_uses_form_sources_and_counts_non_empty_entries() {
        let summary = RecipeDraftLogging.formSummary(
            type: .duplicate,
            ingredients: [
                .init(ingredient: "Egg", amount: "2"),
                .init(ingredient: "", amount: "1")
            ],
            steps: [
                "Beat",
                ""
            ],
            categories: [
                "Breakfast",
                ""
            ],
            note: "Simple"
        )

        #expect(summary.source == .formCreate)
        #expect(summary.inputIngredientCount == 1)
        #expect(summary.inputStepCount == 1)
        #expect(summary.inputCategoryCount == 1)
        #expect(summary.hasNote)
    }

    @Test
    func intentSummary_and_successMetadata_capture_counts_for_intent_update() throws {
        let summary = RecipeDraftLogging.intentSummary(
            source: .intentUpdate,
            ingredientsText: "Egg: 2\nMilk: 100ml",
            stepsText: "Beat\nCook",
            categoriesText: "Breakfast\nQuick",
            note: ""
        )
        let draft = try RecipeFormService.makeDraft(
            name: "Omelet",
            servingSize: 2,
            cookingTime: 10,
            ingredientsText: "Egg: 2\nMilk: 100ml",
            stepsText: "Beat\nCook",
            categoriesText: "Breakfast\nQuick",
            note: ""
        )
        let metadata = summary.successMetadata(
            draft: draft
        )

        #expect(summary.source == .intentUpdate)
        #expect(metadata["source"] == "intent_update")
        #expect(metadata["input_ingredient_count"] == "2")
        #expect(metadata["input_step_count"] == "2")
        #expect(metadata["input_category_count"] == "2")
        #expect(metadata["draft_ingredient_count"] == "2")
        #expect(metadata["draft_step_count"] == "2")
        #expect(metadata["draft_category_count"] == "2")
    }
}
