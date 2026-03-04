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
    func makeDraft_combines_steps_into_single_multiline_text() {
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

        #expect(draft?.combinedSteps == "Chop onion\nSimmer curry")
    }

    @Test
    func makeDraft_removes_empty_steps_only() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "",
                    "  ",
                    " Set rice cooker timer ",
                    " Serve "
                ]
            )
        )

        #expect(draft?.combinedSteps == "Set rice cooker timer\nServe")
    }

    @Test
    func makeDraft_preserves_appliance_words_in_combined_steps() {
        let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: "Curry",
                ingredients: [],
                steps: [
                    "炊飯器で加熱する",
                    "タイマーを3分に設定する"
                ]
            )
        )

        #expect(draft?.combinedSteps == "炊飯器で加熱する\nタイマーを3分に設定する")
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
