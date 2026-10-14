import CookleLibrary
import Foundation
import Testing

struct DailySuggestionSchedulingTests {
    private let candidates: [DailyRecipeSuggestionCandidate] = [
        .init(name: "Soup", stableIdentifier: "soup"),
        .init(name: "Salad", stableIdentifier: "salad")
    ]

    @Test
    func a_passed_fixed_time_is_not_rescheduled_today() throws {
        let calendar = try calendar(timeZone: "UTC")
        let now = try date(year: 2_026, month: 10, day: 14, hour: 19, calendar: calendar)
        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 0,
            now: now,
            calendar: calendar,
            daysAhead: 3
        )

        #expect(suggestions.map(\.identifier) == [
            "daily-recipe-suggestion-2026-10-15",
            "daily-recipe-suggestion-2026-10-16"
        ])
        #expect(suggestions.allSatisfy { suggestion in
            suggestion.notifyDate > now
        })
    }

    @Test
    func the_current_minute_is_not_a_future_notification() throws {
        let calendar = try calendar(timeZone: "UTC")
        let now = try date(year: 2_026, month: 10, day: 14, hour: 18, calendar: calendar)
        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 0,
            now: now,
            calendar: calendar,
            daysAhead: 1
        )

        #expect(suggestions.isEmpty)
    }

    @Test(arguments: [(3, 7, 23), (10, 31, 25)])
    func fixed_wall_clock_time_survives_daylight_saving_changes(
        month: Int,
        day: Int,
        elapsedHours: Int
    ) throws {
        let calendar = try calendar(timeZone: "America/New_York")
        let now = try date(year: 2_026, month: month, day: day, hour: 12, calendar: calendar)
        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 30,
            now: now,
            calendar: calendar,
            daysAhead: 3
        )

        #expect(suggestions.count == 3)
        #expect(Set(suggestions.map(\.identifier)).count == 3)
        for suggestion in suggestions {
            let components = calendar.dateComponents([.hour, .minute], from: suggestion.notifyDate)
            #expect(components.hour == 18)
            #expect(components.minute == 30)
        }
        let first = try #require(suggestions.first)
        let second = try #require(suggestions.dropFirst().first)
        #expect(second.notifyDate.timeIntervalSince(first.notifyDate) == TimeInterval(elapsedHours * 3_600))
    }

    @Test
    func replanning_after_travel_uses_the_new_local_day_and_fixed_time() throws {
        let utc = try calendar(timeZone: "UTC")
        let now = try date(year: 2_026, month: 10, day: 14, hour: 20, calendar: utc)
        let tokyo = try calendar(timeZone: "Asia/Tokyo")
        let losAngeles = try calendar(timeZone: "America/Los_Angeles")
        let tokyoPlan = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 0,
            now: now,
            calendar: tokyo,
            daysAhead: 1
        )
        let losAngelesPlan = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 0,
            now: now,
            calendar: losAngeles,
            daysAhead: 1
        )

        let tokyoSuggestion = try #require(tokyoPlan.first)
        let losAngelesSuggestion = try #require(losAngelesPlan.first)
        #expect(tokyoSuggestion.identifier == "daily-recipe-suggestion-2026-10-15")
        #expect(losAngelesSuggestion.identifier == "daily-recipe-suggestion-2026-10-14")
        #expect(tokyo.component(.hour, from: tokyoSuggestion.notifyDate) == 18)
        #expect(losAngeles.component(.hour, from: losAngelesSuggestion.notifyDate) == 18)
        #expect(tokyoSuggestion.notifyDate > now)
        #expect(losAngelesSuggestion.notifyDate > now)
    }

    @Test
    func the_default_horizon_has_at_most_one_notification_per_local_day() throws {
        let calendar = try calendar(timeZone: "Asia/Tokyo")
        let now = try date(year: 2_026, month: 10, day: 14, hour: 8, calendar: calendar)
        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: 18,
            minute: 0,
            now: now,
            calendar: calendar
        )

        #expect(suggestions.count == 14)
        #expect(Set(suggestions.map(\.identifier)).count == suggestions.count)
        #expect(Set(suggestions.map { suggestion in
            calendar.startOfDay(for: suggestion.notifyDate)
        }).count == suggestions.count)
    }

    @Test(arguments: [(-1, 0), (24, 0), (18, -1), (18, 60)])
    func invalid_fixed_times_produce_no_requests(hour: Int, minute: Int) throws {
        let calendar = try calendar(timeZone: "UTC")
        let now = try date(year: 2_026, month: 10, day: 14, hour: 8, calendar: calendar)
        let suggestions = RecipeOperations.buildDailySuggestions(
            candidates: candidates,
            hour: hour,
            minute: minute,
            now: now,
            calendar: calendar
        )

        #expect(suggestions.isEmpty)
    }
}

private extension DailySuggestionSchedulingTests {
    func calendar(timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        return calendar
    }

    func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: hour)))
    }
}
