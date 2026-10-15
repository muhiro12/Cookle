import CookleLibrary
import Foundation
import Testing

struct AdaptiveRecipeSuggestionTests {
    private let candidates: [DailyRecipeSuggestionCandidate] = [
        .init(name: "Soup", stableIdentifier: "soup"),
        .init(name: "Salad", stableIdentifier: "salad")
    ]

    @Test
    func no_history_and_one_day_have_no_fixed_time_fallback() throws {
        let calendar = try calendar()
        let now = try date(day: 1, hour: 19, minute: 0, calendar: calendar)
        #expect(plan(.init(), now: now, calendar: calendar).isEmpty)
        let state = try state([.init(1, 18, 12), .init(1, 18, 41), .init(1, 20, 0)], calendar: calendar)
        #expect(state.firstOpenMinutesByDay.count == 1)
        #expect(state.learnedMinutes.isEmpty)
        #expect(state.firstOpenMinutesByDay.values.first?[.dinner] == 18 * 60 + 12)
        #expect(plan(state, now: now, calendar: calendar).isEmpty)
    }

    @Test
    func median_uses_first_independent_opens_and_rounds_down() throws {
        let calendar = try calendar()
        let even = try state([.init(1, 18, 12), .init(1, 19, 59), .init(2, 18, 41)], calendar: calendar)
        #expect(even.learnedMinutes[.dinner] == 18 * 60)
        let odd = try state([.init(1, 18, 12), .init(2, 18, 41), .init(3, 19, 2)], calendar: calendar)
        #expect(odd.learnedMinutes[.dinner] == 18 * 60 + 30)
        #expect(odd.learnedMinutes.count == 1)
    }

    @Test(arguments: [(18, 12, 0), (18, 29, 0), (18, 30, 30), (18, 41, 30), (0, 0, 0), (23, 59, 30)])
    func learned_times_round_down_to_the_previous_half_hour(
        hour: Int,
        minute: Int,
        expectedMinute: Int
    ) throws {
        let calendar = try calendar()
        let state = try state([.init(1, hour, minute), .init(2, hour, minute)], calendar: calendar)
        let observedDate = try date(day: 2, hour: hour, minute: minute, calendar: calendar)
        let meal = DiaryOperations.mealType(for: observedDate, calendar: calendar)

        #expect(state.learnedMinutes == [meal: hour * 60 + expectedMinute])
    }

    @Test
    func an_occasional_lunch_does_not_become_a_new_notification_window() throws {
        let calendar = try calendar()
        let state = try state([
            .init(1, 18, 0), .init(2, 18, 0), .init(3, 12, 0), .init(3, 18, 0),
            .init(4, 18, 0), .init(5, 12, 0), .init(5, 18, 0)
        ], calendar: calendar)
        #expect(state.firstOpenMinutesByDay.count == 5)
        #expect(state.learnedMinutes[.lunch] == nil)
        #expect(state.learnedMinutes[.dinner] == 18 * 60)
    }

    @Test
    func exactly_half_the_independent_days_is_enough_after_two_days() throws {
        let calendar = try calendar()
        let state = try state([
            .init(1, 18, 0), .init(2, 18, 0), .init(3, 12, 41), .init(3, 18, 0), .init(4, 12, 12)
        ], calendar: calendar)
        #expect(state.learnedMinutes[.lunch] == 12 * 60)
    }

    @Test
    func notification_only_days_do_not_change_the_denominator_or_clock() throws {
        let calendar = try calendar()
        var state = try state([.init(1, 18, 12), .init(2, 18, 41)], calendar: calendar)
        for day in 3...17 {
            state = RecipeOperations.recordSuggestionUsage(
                in: state,
                at: try date(day: day, hour: 20, minute: 59, calendar: calendar),
                isNotificationResponse: true,
                calendar: calendar
            )
        }
        #expect(state.firstOpenMinutesByDay.isEmpty)
        #expect(state.learnedMinutes[.dinner] == 18 * 60)
        #expect(state.lastUsedAt[.dinner] == (try date(day: 17, hour: 20, minute: 59, calendar: calendar)))
        let now = try date(day: 17, hour: 21, minute: 0, calendar: calendar)
        #expect(!plan(state, now: now, calendar: calendar).isEmpty)
    }

    @Test
    func night_use_does_not_renew_an_abandoned_breakfast() throws {
        let calendar = try calendar()
        var state = try state([.init(1, 8, 0), .init(1, 18, 0), .init(2, 8, 0), .init(2, 18, 0)], calendar: calendar)
        for day in 3...17 {
            state = RecipeOperations.recordSuggestionUsage(
                in: state,
                at: try date(day: day, hour: 18, minute: 0, calendar: calendar),
                isNotificationResponse: true,
                calendar: calendar
            )
        }
        #expect(state.learnedMinutes[.breakfast] == nil)
        #expect(state.lastUsedAt[.breakfast] == nil)
        #expect(state.learnedMinutes[.dinner] == 18 * 60)
    }

    @Test
    func a_late_notification_tap_counts_at_the_actual_opened_meal() throws {
        let calendar = try calendar()
        let before = try state([.init(1, 8, 0), .init(2, 8, 0)], calendar: calendar)
        let after = RecipeOperations.recordSuggestionUsage(
            in: before,
            at: try date(day: 3, hour: 20, minute: 0, calendar: calendar),
            isNotificationResponse: true,
            calendar: calendar
        )
        #expect(after.lastUsedAt[.breakfast] == before.lastUsedAt[.breakfast])
        #expect(after.lastUsedAt[.dinner] != nil)
        #expect(after.learnedMinutes[.dinner] == nil)
        #expect(after.firstOpenMinutesByDay == before.firstOpenMinutesByDay)
    }

    @Test
    func expiry_is_exactly_fourteen_calendar_days_from_that_meals_last_use() throws {
        let calendar = try calendar()
        let state = try state([.init(1, 18, 0), .init(2, 18, 0)], calendar: calendar)
        let expiry = try date(day: 16, hour: 18, minute: 0, calendar: calendar)
        #expect(RecipeOperations.reconciledSuggestionState(
            state, now: expiry.addingTimeInterval(-1), calendar: calendar
        )
        .learnedMinutes[.dinner] != nil)
        #expect(RecipeOperations.reconciledSuggestionState(
            state, now: expiry, calendar: calendar
        )
        .learnedMinutes[.dinner] == nil)
        #expect(plan(state, now: expiry, calendar: calendar).isEmpty)
    }

    @Test
    func history_stays_within_one_small_fourteen_day_record() throws {
        let calendar = try calendar()
        var state = AdaptiveRecipeSuggestionState()
        for day in 1...28 {
            for hour in [8, 12, 18] {
                state = RecipeOperations.recordSuggestionUsage(
                    in: state,
                    at: try date(day: day, hour: hour, minute: 12, calendar: calendar),
                    isNotificationResponse: false,
                    calendar: calendar
                )
            }
        }
        #expect(state.firstOpenMinutesByDay.count == 14)
        #expect(state.firstOpenMinutesByDay.values.reduce(0) { $0 + $1.count } == 42)
        #expect(state.learnedMinutes.count == 3)
        #expect(state.lastUsedAt.count == 3)
        let encoded = try #require(state.encodedString())
        #expect(encoded.utf8.count < 8_192)
        #expect(AdaptiveRecipeSuggestionState.decoded(from: encoded) == state)
        #expect(AdaptiveRecipeSuggestionState.decoded(from: "invalid") == nil)
    }

    @Test
    func schedule_is_future_unique_bounded_and_idempotent() throws {
        let calendar = try calendar()
        let state = try state([
            .init(1, 8, 12), .init(1, 12, 41), .init(1, 18, 12),
            .init(2, 8, 12), .init(2, 12, 41), .init(2, 18, 12)
        ], calendar: calendar)
        let now = try date(day: 3, hour: 6, minute: 0, calendar: calendar)
        let suggestions = plan(state, now: now, calendar: calendar)
        #expect(!suggestions.isEmpty)
        #expect(suggestions.count <= 42)
        #expect(suggestions.allSatisfy { $0.notifyDate > now })
        #expect(Set(suggestions.map(\.identifier)).count == suggestions.count)
        let byDay = Dictionary(grouping: suggestions) { calendar.startOfDay(for: $0.notifyDate) }
        #expect(byDay.values.allSatisfy { $0.count <= 3 })
        #expect(suggestions.contains { $0.identifier.hasSuffix("-breakfast") })
        #expect(suggestions.contains { $0.identifier.hasSuffix("-lunch") })
        #expect(suggestions.contains { $0.identifier.hasSuffix("-dinner") })
        let again = plan(state, now: now, calendar: calendar)
        #expect(suggestions.map(\.identifier) == again.map(\.identifier))
        #expect(suggestions.map(\.notifyDate) == again.map(\.notifyDate))
        let reconciled = RecipeOperations.reconciledSuggestionState(state, now: now, calendar: calendar)
        #expect(RecipeOperations.reconciledSuggestionState(reconciled, now: now, calendar: calendar) == reconciled)
    }

    @Test
    func opening_a_meal_cancels_only_that_meals_remaining_suggestion_today() throws {
        let calendar = try calendar()
        let initial = try state([
            .init(1, 8, 0), .init(1, 12, 30), .init(1, 18, 30),
            .init(2, 8, 0), .init(2, 12, 30), .init(2, 18, 30)
        ], calendar: calendar)
        let now = try date(day: 3, hour: 11, minute: 5, calendar: calendar)
        let used = RecipeOperations.recordSuggestionUsage(
            in: initial, at: now, isNotificationResponse: true, calendar: calendar
        )
        let today = plan(used, now: now, calendar: calendar).filter { suggestion in
            calendar.isDate(suggestion.notifyDate, inSameDayAs: now)
        }
        #expect(today.count == 1)
        #expect(today.first?.identifier.hasSuffix("-dinner") == true)
        #expect(used.learnedMinutes[.lunch] == initial.learnedMinutes[.lunch])
    }

    @Test(arguments: [
        (10, 59, "breakfast"), (11, 0, "lunch"), (15, 59, "lunch"),
        (16, 0, "dinner"), (0, 0, "breakfast")
    ])
    func meal_boundaries_match_the_existing_diary(hour: Int, minute: Int, meal: String) throws {
        let calendar = try calendar()
        let state = try state([.init(1, hour, minute)], calendar: calendar)
        #expect(state.lastUsedAt.keys.first?.id == meal)
    }

    @Test
    func local_midnight_starts_a_new_day_without_reusing_yesterdays_first_open() throws {
        let calendar = try calendar()
        let state = try state([.init(1, 23, 59), .init(2, 0, 12)], calendar: calendar)
        #expect(state.firstOpenMinutesByDay.count == 2)
        #expect(state.firstOpenMinutesByDay.values.compactMap { $0[.dinner] }.count == 1)
        #expect(state.firstOpenMinutesByDay.values.compactMap { $0[.breakfast] }.count == 1)
    }

    @Test(arguments: [(3, 7), (10, 31)])
    func daylight_saving_keeps_one_request_per_local_day(month: Int, day: Int) throws {
        let calendar = try calendar("America/New_York")
        let first = try date(day: day - 1, hour: 8, minute: 12, calendar: calendar, month: month)
        let second = try date(day: day, hour: 8, minute: 41, calendar: calendar, month: month)
        var state = RecipeOperations.recordSuggestionUsage(
            in: .init(), at: first, isNotificationResponse: false, calendar: calendar
        )
        state = RecipeOperations.recordSuggestionUsage(
            in: state, at: second, isNotificationResponse: false, calendar: calendar
        )
        let suggestions = plan(state, now: second, calendar: calendar)
        #expect(!suggestions.isEmpty)
        #expect(Set(suggestions.map { calendar.startOfDay(for: $0.notifyDate) }).count == suggestions.count)
        #expect(suggestions.allSatisfy { calendar.component(.hour, from: $0.notifyDate) == 8 })
    }

    @Test
    func a_missing_spring_clock_time_uses_the_next_valid_time_once() throws {
        let calendar = try calendar("America/New_York")
        let first = try date(day: 6, hour: 2, minute: 41, calendar: calendar, month: 3)
        let second = try date(day: 7, hour: 2, minute: 41, calendar: calendar, month: 3)
        var state = RecipeOperations.recordSuggestionUsage(
            in: .init(), at: first, isNotificationResponse: false, calendar: calendar
        )
        state = RecipeOperations.recordSuggestionUsage(
            in: state, at: second, isNotificationResponse: false, calendar: calendar
        )
        let transition = try date(day: 8, hour: 12, minute: 0, calendar: calendar, month: 3)
        let requests = plan(state, now: second, calendar: calendar).filter { suggestion in
            calendar.isDate(suggestion.notifyDate, inSameDayAs: transition)
        }
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(calendar.component(.hour, from: request.notifyDate) == 3)
        #expect(calendar.component(.minute, from: request.notifyDate) == 0)
    }

    @Test
    func a_repeated_fall_clock_time_uses_the_first_occurrence_once() throws {
        let calendar = try calendar("America/New_York")
        let state = try state([.init(30, 1, 41), .init(31, 1, 41)], calendar: calendar)
        let now = try date(day: 1, hour: 0, minute: 0, calendar: calendar, month: 11)
        let requests = plan(state, now: now, calendar: calendar).filter { suggestion in
            calendar.isDate(suggestion.notifyDate, inSameDayAs: now)
        }
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(calendar.component(.hour, from: request.notifyDate) == 1)
        #expect(calendar.component(.minute, from: request.notifyDate) == 30)
        #expect(calendar.timeZone.secondsFromGMT(for: request.notifyDate) == -14_400)
    }

    @Test
    func travel_keeps_learned_wall_clock_minutes() throws {
        let tokyo = try calendar("Asia/Tokyo")
        let state = try state([.init(1, 18, 12), .init(2, 18, 41)], calendar: tokyo)
        let now = try date(day: 3, hour: 12, minute: 0, calendar: try calendar("America/Los_Angeles"))
        let destination = try calendar("America/Los_Angeles")
        let suggestions = plan(state, now: now, calendar: destination)
        #expect(!suggestions.isEmpty)
        #expect(suggestions.allSatisfy { destination.component(.hour, from: $0.notifyDate) == 18 })
        #expect(suggestions.allSatisfy { destination.component(.minute, from: $0.notifyDate) == 0 })
    }
}

private extension AdaptiveRecipeSuggestionTests {
    struct Open {
        let day: Int
        let hour: Int
        let minute: Int

        init(_ day: Int, _ hour: Int, _ minute: Int) {
            self.day = day
            self.hour = hour
            self.minute = minute
        }
    }

    func calendar(_ zone: String = "UTC") throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    func date(day: Int, hour: Int, minute: Int, calendar: Calendar, month: Int? = nil) throws -> Date {
        let fixtureYear = 2_026
        let fixtureMonth = 10
        return try #require(calendar.date(from: .init(
            year: fixtureYear, month: month ?? fixtureMonth, day: day, hour: hour, minute: minute
        )))
    }

    func state(_ opens: [Open], calendar: Calendar) throws -> AdaptiveRecipeSuggestionState {
        var state = AdaptiveRecipeSuggestionState()
        for open in opens {
            state = RecipeOperations.recordSuggestionUsage(
                in: state,
                at: try date(day: open.day, hour: open.hour, minute: open.minute, calendar: calendar),
                isNotificationResponse: false,
                calendar: calendar
            )
        }
        return state
    }

    func plan(_ state: AdaptiveRecipeSuggestionState, now: Date, calendar: Calendar) -> [DailyRecipeSuggestion] {
        RecipeOperations.buildAdaptiveSuggestions(candidates: candidates, state: state, now: now, calendar: calendar)
    }
}
