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
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
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
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
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

    @Test
    func buildSuggestions_preserves_existing_identifier_format_without_zero_padding() {
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
                .init(name: "Alpha", stableIdentifier: "recipe-alpha")
            ],
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
            now: now,
            calendar: calendar,
            daysAhead: 3
        )

        #expect(suggestions.count == 3)
        #expect(suggestions[0].identifier == "daily-recipe-suggestion-2026-1-1")
        #expect(suggestions[1].identifier == "daily-recipe-suggestion-2026-1-2")
        #expect(suggestions[2].identifier == "daily-recipe-suggestion-2026-1-3")
    }

    @Test
    func buildSuggestions_prefersInformativeCandidatesWhenEnoughExist() throws {
        let calendar = testCalendar()
        let now = try testDate(
            calendar: calendar
        )

        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(
                    name: "Informative Alpha",
                    stableIdentifier: "informative-alpha",
                    hasPhoto: true
                ),
                .init(
                    name: "Informative Beta",
                    stableIdentifier: "informative-beta",
                    ingredientCount: 3
                ),
                .init(
                    name: "Ordinary",
                    stableIdentifier: "ordinary"
                )
            ],
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
            now: now,
            calendar: calendar,
            daysAhead: 5
        )

        #expect(suggestions.isEmpty == false)
        #expect(
            suggestions.allSatisfy { suggestion in
                suggestion.recipeName.hasPrefix("Informative")
            }
        )
    }

    @Test
    func buildSuggestions_excludesRecentlyCookedRecipesWhenPoolRemains() throws {
        let calendar = testCalendar()
        let now = try testDate(
            calendar: calendar
        )
        let yesterday = try #require(
            calendar.date(
                byAdding: .day,
                value: -1,
                to: now
            )
        )
        let olderDate = try #require(
            calendar.date(
                byAdding: .day,
                value: -10,
                to: now
            )
        )

        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(
                    name: "Recent",
                    stableIdentifier: "recent",
                    hasPhoto: true,
                    lastCookedDate: yesterday
                ),
                .init(
                    name: "Older",
                    stableIdentifier: "older",
                    hasPhoto: true,
                    lastCookedDate: olderDate
                ),
                .init(
                    name: "Never",
                    stableIdentifier: "never",
                    hasPhoto: true
                )
            ],
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
            now: now,
            calendar: calendar,
            daysAhead: 5
        )

        #expect(suggestions.isEmpty == false)
        #expect(
            suggestions.allSatisfy { suggestion in
                suggestion.recipeName != "Recent"
            }
        )
    }

    @Test
    func buildSuggestions_ignoresBlankAndDuplicateCandidates() throws {
        let calendar = testCalendar()
        let now = try testDate(
            calendar: calendar
        )

        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: [
                .init(name: "  Alpha  Soup  ", stableIdentifier: "alpha"),
                .init(name: "Duplicate Alpha", stableIdentifier: "alpha"),
                .init(name: " ", stableIdentifier: "blank-name"),
                .init(name: "Blank Identifier", stableIdentifier: " ")
            ],
            hour: DailySuggestionTimePolicy.defaultHour,
            minute: DailySuggestionTimePolicy.minimumTimeComponent,
            now: now,
            calendar: calendar,
            daysAhead: 3
        )

        #expect(
            suggestions.map(\.recipeName) == [
                "Alpha Soup",
                "Alpha Soup",
                "Alpha Soup"
            ]
        )
    }
}

private extension DailyRecipeSuggestionServiceTests {
    enum TestValues {
        static let year = 2_026
        static let hour = 10
    }

    func testCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        return calendar
    }

    func testDate(
        calendar: Calendar
    ) throws -> Date {
        try #require(
            calendar.date(
                from: .init(
                    year: TestValues.year,
                    month: 1,
                    day: 1,
                    hour: TestValues.hour,
                    minute: 0
                )
            )
        )
    }
}
