import CookleLibrary
import Foundation
import Testing

struct MealSuggestionTimingTests {
    @Test(arguments: [(18, 12, 0), (18, 29, 0), (18, 30, 30), (18, 41, 30), (0, 0, 0), (23, 59, 30)])
    func observed_times_round_down_to_the_previous_half_hour(
        hour: Int,
        minute: Int,
        expectedMinute: Int
    ) throws {
        let calendar = try calendar(timeZone: "Asia/Tokyo")
        let observedDate = try date(hour: hour, minute: minute, calendar: calendar)
        let times = RecipeOperations.mealSuggestionTimes(
            from: [.dinner: observedDate],
            isEnabled: true,
            calendar: calendar
        )
        let time = try #require(times[.dinner])

        #expect(time.hour == hour)
        #expect(time.minute == expectedMinute)
        #expect(time.second == 0)
    }

    @Test
    func a_night_only_observation_does_not_create_morning_or_lunch_times() throws {
        let calendar = try calendar(timeZone: "Asia/Tokyo")
        let times = RecipeOperations.mealSuggestionTimes(
            from: [.dinner: try date(hour: 18, minute: 41, calendar: calendar)],
            isEnabled: true,
            calendar: calendar
        )

        #expect(times.count == 1)
        #expect(times[.breakfast] == nil)
        #expect(times[.lunch] == nil)
        #expect(times[.dinner]?.hour == 18)
        #expect(times[.dinner]?.minute == 30)
    }

    @Test
    func three_observed_meals_produce_one_time_each() throws {
        let calendar = try calendar(timeZone: "Asia/Tokyo")
        let times = RecipeOperations.mealSuggestionTimes(
            from: [
                .breakfast: try date(hour: 8, minute: 12, calendar: calendar),
                .lunch: try date(hour: 12, minute: 41, calendar: calendar),
                .dinner: try date(hour: 18, minute: 12, calendar: calendar)
            ],
            isEnabled: true,
            calendar: calendar
        )

        #expect(times.count == 3)
        #expect(times[.breakfast]?.hour == 8)
        #expect(times[.breakfast]?.minute == 0)
        #expect(times[.lunch]?.hour == 12)
        #expect(times[.lunch]?.minute == 30)
        #expect(times[.dinner]?.hour == 18)
        #expect(times[.dinner]?.minute == 0)
    }

    @Test
    func no_observations_do_not_invent_a_fixed_fallback() {
        #expect(RecipeOperations.mealSuggestionTimes(from: [:], isEnabled: true).isEmpty)
    }

    @Test
    func notifications_off_produces_no_times_even_with_observations() throws {
        let calendar = try calendar(timeZone: "Asia/Tokyo")
        let times = RecipeOperations.mealSuggestionTimes(
            from: [
                .breakfast: try date(hour: 8, minute: 12, calendar: calendar),
                .lunch: try date(hour: 12, minute: 41, calendar: calendar),
                .dinner: try date(hour: 18, minute: 12, calendar: calendar)
            ],
            isEnabled: false,
            calendar: calendar
        )

        #expect(times.isEmpty)
    }

    @Test
    func rounding_uses_the_supplied_local_time_zone() throws {
        let utc = try calendar(timeZone: "UTC")
        let observedDate = try date(hour: 20, minute: 41, calendar: utc)
        let tokyoTimes = RecipeOperations.mealSuggestionTimes(
            from: [.dinner: observedDate],
            isEnabled: true,
            calendar: try calendar(timeZone: "Asia/Tokyo")
        )
        let losAngelesTimes = RecipeOperations.mealSuggestionTimes(
            from: [.dinner: observedDate],
            isEnabled: true,
            calendar: try calendar(timeZone: "America/Los_Angeles")
        )

        #expect(tokyoTimes[.dinner]?.hour == 5)
        #expect(tokyoTimes[.dinner]?.minute == 30)
        #expect(losAngelesTimes[.dinner]?.hour == 13)
        #expect(losAngelesTimes[.dinner]?.minute == 30)
    }
}

private extension MealSuggestionTimingTests {
    func calendar(timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        return calendar
    }

    func date(hour: Int, minute: Int, calendar: Calendar) throws -> Date {
        let observationYear = 2_026
        let observationMonth = 10
        let observationDay = 14
        let observationSecond = 45
        return try #require(calendar.date(from: .init(
            year: observationYear,
            month: observationMonth,
            day: observationDay,
            hour: hour,
            minute: minute,
            second: observationSecond
        )))
    }
}
