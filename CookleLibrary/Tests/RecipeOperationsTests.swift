@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct RecipeOperationsTests {
    let context = makeTestContext()

    @Test
    func search_returns_recipes_matching_prefix() throws {
        _ = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = Recipe.create(
            context: context,
            name: "Spaghetti",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try RecipeOperations.search(
            context: context,
            text: "Panc"
        )

        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }

    @Test
    func buildDailySuggestions_returns_stable_public_entries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        let now = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 1,
                    day: 1,
                    hour: 10,
                    minute: 0
                )
            )
        )

        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: [
                .init(name: "Alpha", stableIdentifier: "recipe-alpha"),
                .init(name: "Beta", stableIdentifier: "recipe-beta")
            ],
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
            now: now,
            calendar: calendar,
            daysAhead: 2
        )

        #expect(suggestions.count == 2)
        #expect(
            suggestions.allSatisfy { suggestion in
                suggestion.identifier.hasPrefix("daily-recipe-suggestion-")
            }
        )
        #expect(
            suggestions.allSatisfy { suggestion in
                suggestion.stableIdentifier.hasPrefix("recipe-")
            }
        )
    }

    @Test
    func deterministic_content_helpers_normalize_recipe_content() throws {
        let blurb = RecipeOperations.makeBlurb(
            request: .init(
                steps: ["1. Plate with basil and olive oil"],
                ingredients: ["Tomato", "Pasta"],
                note: ""
            )
        )
        let conceptDraft = try #require(
            RecipeOperations.makeImageConceptDraft(
                request: .init(
                    name: "  Tomato Pasta  ",
                    ingredients: [
                        " Tomato ",
                        " "
                    ],
                    steps: [
                        "Serve with basil",
                        "Boil pasta"
                    ]
                )
            )
        )

        #expect(blurb == "Plate with basil and olive oil")
        #expect(conceptDraft.title == "Tomato Pasta")
        #expect(conceptDraft.ingredients == ["Tomato"])
        #expect(conceptDraft.combinedSteps == "Serve with basil")
    }
}
