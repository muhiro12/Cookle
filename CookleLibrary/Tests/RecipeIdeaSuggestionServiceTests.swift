@testable import CookleLibrary
import Testing

struct RecipeIdeaSuggestionServiceTests {
    @available(iOS 26.0, *)
    @Test
    func normalizedIngredients_trimsDeduplicatesAndLimitsInput() {
        let ingredients = RecipeIdeaSuggestionService.normalizedIngredients(
            [
                " Eggs ",
                "eggs",
                "Carrot",
                "Onion",
                "Tomato",
                "Rice",
                "Miso",
                "Spinach",
                "Tofu",
                "Potato"
            ]
        )

        #expect(ingredients == [
            "Eggs",
            "Carrot",
            "Onion",
            "Tomato",
            "Rice",
            "Miso",
            "Spinach",
            "Tofu"
        ])
    }

    @available(iOS 26.0, *)
    @Test
    func sanitizedSuggestions_dropsBlankAndDuplicateTitles() {
        let suggestions = RecipeIdeaSuggestionService.sanitizedSuggestions(
            [
                .init(
                    title: " Pantry Bowl ",
                    flavorDirection: " Savory ",
                    roughApproach: " Use the selected ingredients loosely. ",
                    coreIngredients: [
                        "Eggs",
                        "Unknown"
                    ]
                ),
                .init(
                    title: "pantry bowl",
                    flavorDirection: "Duplicate",
                    roughApproach: "Duplicate",
                    coreIngredients: [
                        "Carrot"
                    ]
                ),
                .init(
                    title: "",
                    flavorDirection: "Blank",
                    roughApproach: "Blank",
                    coreIngredients: []
                )
            ],
            inputIngredients: [
                "Eggs",
                "Carrot"
            ]
        )

        #expect(suggestions.count == 1)
        #expect(suggestions[0].title == "Pantry Bowl")
        #expect(suggestions[0].flavorDirection == "Savory")
        #expect(suggestions[0].coreIngredients == ["Eggs"])
    }

    @available(iOS 26.0, *)
    @Test
    func fallbackSuggestions_doNotCreateFullRecipeContent() {
        let suggestions = RecipeIdeaSuggestionService.fallbackSuggestions(
            ingredients: [
                "Eggs",
                "Rice",
                "Spinach"
            ]
        )

        #expect(suggestions.count == 3)
        #expect(suggestions.allSatisfy { suggestion in
            suggestion.title.isNotEmpty
                && suggestion.coreIngredients.isNotEmpty
                && suggestion.roughApproach.contains("\n") == false
        })
    }
}
