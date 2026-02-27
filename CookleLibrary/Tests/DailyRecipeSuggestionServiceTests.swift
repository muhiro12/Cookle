@testable import CookleLibrary
import Foundation
import Testing

struct DailyRecipeSuggestionServiceTests {
    @Test
    func buildSuggestions_creates_stable_entries_without_adjacent_duplicates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .init(secondsFromGMT: 0)!
        let now = calendar.date(
            from: .init(
                year: 2_026,
                month: 1,
                day: 1,
                hour: 10,
                minute: 0
            )
        )!
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(name: "Alpha", stableIdentifier: "1"),
                .init(name: "Beta", stableIdentifier: "2")
            ],
            now: now,
            calendar: calendar,
            hour: 20,
            minute: 0,
            daysAhead: 5
        )

        #expect(suggestions.count == 5)
        for index in suggestions.indices.dropFirst() {
            #expect(suggestions[index].recipeName != suggestions[index - 1].recipeName)
        }
    }
}
