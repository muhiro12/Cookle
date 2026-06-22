@testable import CookleLibrary
import Testing

struct RecipeBlurbServiceTests {
    @Test
    func makeBlurb_uses_first_meaningful_step() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [
                    "Mix",
                    "Simmer slowly until glossy"
                ],
                ingredients: ["Onion", "Soy Sauce"],
                note: "Family favorite"
            )
        )

        #expect(blurb == "Simmer slowly until glossy")
    }

    @Test
    func makeBlurb_falls_back_to_first_step_when_all_steps_are_short() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [
                    "Mix",
                    "Bake"
                ],
                ingredients: [],
                note: ""
            )
        )

        #expect(blurb == "Mix")
    }

    @Test
    func makeBlurb_strips_numeric_and_bullet_prefixes() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [
                    "1)   Whisk the eggs thoroughly",
                    "• Serve warm"
                ],
                ingredients: [],
                note: ""
            )
        )

        #expect(blurb == "Whisk the eggs thoroughly")
    }

    @Test
    func makeBlurb_collapses_internal_whitespace() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [
                    "Cook\n   slowly\tuntil  tender"
                ],
                ingredients: [],
                note: ""
            )
        )

        #expect(blurb == "Cook slowly until tender")
    }

    @Test
    func makeBlurb_falls_back_to_note_when_steps_are_empty() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [],
                ingredients: [],
                note: "  - Best served chilled \nSecond line"
            )
        )

        #expect(blurb == "Best served chilled")
    }

    @Test
    func makeBlurb_falls_back_to_ingredients_when_steps_and_note_are_empty() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [],
                ingredients: [
                    " Onion ",
                    "Carrot",
                    "Potato"
                ],
                note: "   "
            )
        )

        #expect(blurb == "Onion, Carrot")
    }

    @Test
    func makeBlurb_returns_nil_when_all_inputs_are_empty() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: [],
                ingredients: [],
                note: " \n "
            )
        )

        #expect(blurb == nil)
    }

    @Test
    func makeBlurb_truncates_to_max_length_with_ascii_ellipsis() {
        let blurb = RecipeBlurbService.makeBlurb(
            request: .init(
                steps: ["Supercalifragilisticexpialidocious"],
                ingredients: [],
                note: ""
            ),
            maxLength: 10
        )

        #expect(blurb == "Superca...")
    }
}
