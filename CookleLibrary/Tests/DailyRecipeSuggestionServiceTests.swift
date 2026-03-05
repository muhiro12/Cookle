@testable import CookleLibrary
import Foundation
import Testing

struct DailyRecipeSuggestionServiceTests {
    @Test
    func buildSuggestions_creates_stable_entries_without_adjacent_duplicates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        guard let now = calendar.date(
            from: .init(
                year: 2_026,
                month: 1,
                day: 1,
                hour: 10,
                minute: 0
            )
        ) else {
            Issue.record("Failed to build test date")
            return
        }
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(name: "Alpha", stableIdentifier: "1"),
                .init(name: "Beta", stableIdentifier: "2")
            ],
            hour: 20,
            minute: 0,
            now: now,
            calendar: calendar,
            daysAhead: 5
        )

        #expect(suggestions.count == 5)
        for index in suggestions.indices.dropFirst() {
            #expect(suggestions[index].recipeName != suggestions[index - 1].recipeName)
        }
    }

    @Test
    func buildSuggestions_preserves_stable_identifier_for_selected_recipe() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        guard let now = calendar.date(
            from: .init(
                year: 2_026,
                month: 1,
                day: 1,
                hour: 10,
                minute: 0
            )
        ) else {
            Issue.record("Failed to build test date")
            return
        }
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(name: "Alpha", stableIdentifier: "recipe-alpha"),
                .init(name: "Beta", stableIdentifier: "recipe-beta")
            ],
            hour: 20,
            minute: 0,
            now: now,
            calendar: calendar,
            daysAhead: 2
        )

        #expect(suggestions.count == 2)
        for suggestion in suggestions {
            if suggestion.recipeName == "Alpha" {
                #expect(suggestion.stableIdentifier == "recipe-alpha")
            } else if suggestion.recipeName == "Beta" {
                #expect(suggestion.stableIdentifier == "recipe-beta")
            } else {
                Issue.record("Unexpected recipe name")
            }
        }
    }
}
