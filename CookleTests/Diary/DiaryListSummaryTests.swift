import Testing

@testable import Cookle

@MainActor
struct DiaryListSummaryTests {
    @Test
    func text_prefers_recipe_names_when_available() {
        let summary = DiaryListSummary.text(
            recipeNames: ["Toast", "Soup"],
            note: "Ignored"
        )

        #expect(summary == "Toast, Soup")
    }

    @Test
    func text_uses_collapsed_note_when_no_recipes() {
        let summary = DiaryListSummary.text(
            recipeNames: [],
            note: "  First line\nSecond line  "
        )

        #expect(summary == "First line Second line")
    }

    @Test
    func text_falls_back_when_recipes_and_note_are_empty() {
        let summary = DiaryListSummary.text(
            recipeNames: [],
            note: " \n "
        )

        #expect(summary == "No recipes or note yet")
    }
}
