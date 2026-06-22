@testable import CookleLibrary
import Testing

struct RecipeImageConceptServiceTests {
    @Test
    func makeDraft_returns_nil_when_title_is_empty() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "  \n  ",
                ingredients: ["Onion"],
                steps: ["Simmer"]
            )
        )

        #expect(draft == nil)
    }

    @Test
    func makeDraft_preserves_title_after_whitespace_normalization() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "  Curry   Rice \n",
                ingredients: [],
                steps: []
            )
        )

        #expect(draft?.title == "Curry Rice")
    }

    @Test
    func makeDraft_preserves_ingredient_order() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [
                    " Onion ",
                    "Carrot",
                    "Potato"
                ],
                steps: []
            )
        )

        #expect(draft?.ingredients == ["Onion", "Carrot", "Potato"])
    }

    @Test
    func makeDraft_removes_empty_ingredients_only() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [
                    "",
                    "  ",
                    " Onion ",
                    "Rice Cooker"
                ],
                steps: []
            )
        )

        #expect(draft?.ingredients == ["Onion", "Rice Cooker"])
    }

    @Test
    func makeDraft_returns_nil_combined_steps_when_steps_are_process_only() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "Chop onion",
                    "Simmer curry"
                ]
            )
        )

        #expect(draft?.combinedSteps == nil)
    }

    @Test
    func makeDraft_keeps_only_finish_or_serving_steps() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "",
                    "  ",
                    " Set rice cooker timer ",
                    " Garnish with parsley ",
                    " Serve "
                ]
            )
        )

        #expect(draft?.combinedSteps == "Garnish with parsley\nServe")
    }

    @Test
    func makeDraft_keeps_japanese_finish_steps_in_combined_steps() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "炊飯器で加熱する",
                    "器に盛り付ける",
                    "青ねぎを添える"
                ]
            )
        )

        #expect(draft?.combinedSteps == "器に盛り付ける\n青ねぎを添える")
    }

    @Test
    func makeDraft_returns_nil_combined_steps_when_no_non_empty_steps_exist() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "",
                    " \n "
                ]
            )
        )

        #expect(draft?.combinedSteps == nil)
    }
}
