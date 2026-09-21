@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// The Diary widget's `.today` mode asks `DiaryOperations.diary(on:context:)`
// with the entry's date and schedules its next refresh for
// `CookleWidgetTimelineRefreshPolicy.startOfNextDay`.
//
// `CookleWidgetTimelineRefreshPolicyTests` already pins when that refresh
// fires, including across both daylight-saving transitions. What was missing is
// the other half: that the *content* actually changes at the boundary, and what
// happens to "today" when the device's time zone moves.
@MainActor
struct DiaryWidgetDayBoundaryTests {
    @Test
    func todays_diary_is_not_returned_once_the_day_rolls_over() throws {
        let context = makeTestContext()
        let calendar = Self.calendar(secondsFromGMT: .zero)
        let today = Self.date(secondsFromGMT: .zero, hour: Value.middayHour)
        _ = Diary.create(
            context: context,
            content: .init(date: today, objects: [], note: "Baked")
        )

        #expect(
            try DiaryOperations.diary(
                on: today,
                context: context,
                calendar: calendar
            )?.note == "Baked"
        )

        // The instant the widget's own refresh policy wakes it up.
        let nextDay = try #require(
            CookleWidgetTimelineRefreshPolicy.startOfNextDay(
                after: today,
                calendar: calendar
            )
        )

        #expect(
            try DiaryOperations.diary(
                on: nextDay,
                context: context,
                calendar: calendar
            ) == nil
        )
    }

    @Test
    func a_diary_is_still_found_at_the_first_and_last_instant_of_its_day() throws {
        let context = makeTestContext()
        let calendar = Self.calendar(secondsFromGMT: .zero)
        let midday = Self.date(secondsFromGMT: .zero, hour: Value.middayHour)
        _ = Diary.create(
            context: context,
            content: .init(date: midday, objects: [], note: "Baked")
        )

        let startOfDay = calendar.startOfDay(for: midday)
        let endOfDay = try #require(
            CookleWidgetTimelineRefreshPolicy.startOfNextDay(
                after: midday,
                calendar: calendar
            )
        )
            .addingTimeInterval(-1)

        #expect(
            try DiaryOperations.diary(
                on: startOfDay,
                context: context,
                calendar: calendar
            )?.note == "Baked"
        )
        #expect(
            try DiaryOperations.diary(
                on: endOfDay,
                context: context,
                calendar: calendar
            )?.note == "Baked"
        )
    }

    @Test
    func the_same_instant_belongs_to_different_days_in_different_time_zones() throws {
        let context = makeTestContext()
        // 15:00 UTC is already the next calendar day in UTC+9.
        let instant = Self.date(secondsFromGMT: .zero, hour: Value.lateAfternoonHour)
        _ = Diary.create(
            context: context,
            content: .init(date: instant, objects: [], note: "Baked")
        )

        let utc = Self.calendar(secondsFromGMT: .zero)
        let tokyo = Self.calendar(secondsFromGMT: Value.tokyoOffsetSeconds)

        #expect(utc.startOfDay(for: instant) != tokyo.startOfDay(for: instant))

        // Looked up with the same instant, both still find it — the lookup
        // compares the diary's day to the supplied date's day in one calendar,
        // so moving time zone shifts both sides together.
        #expect(
            try DiaryOperations.diary(
                on: instant,
                context: context,
                calendar: utc
            )?.note == "Baked"
        )
        #expect(
            try DiaryOperations.diary(
                on: instant,
                context: context,
                calendar: tokyo
            )?.note == "Baked"
        )
    }

    @Test
    func a_diary_stays_todays_until_the_local_day_ends() throws {
        let context = makeTestContext()
        // Recorded at 15:00 UTC, which is 00:00 the next day in UTC+9.
        let instant = Self.date(secondsFromGMT: .zero, hour: Value.lateAfternoonHour)
        _ = Diary.create(
            context: context,
            content: .init(date: instant, objects: [], note: "Baked")
        )

        let tokyo = Self.calendar(secondsFromGMT: Value.tokyoOffsetSeconds)
        // Two hours later the device is in Tokyo. Local "now" is 02:00 on the
        // following Tokyo day, and the diary recorded two hours ago is on that
        // same Tokyo day — so it is still today's.
        let laterSameTokyoDay = instant.addingTimeInterval(Value.twoHoursInSeconds)
        #expect(
            try DiaryOperations.diary(
                on: laterSameTokyoDay,
                context: context,
                calendar: tokyo
            )?.note == "Baked"
        )

        // A day later in Tokyo it is no longer today's, which is the behaviour
        // the widget's midnight refresh is there to pick up.
        let nextTokyoDay = instant.addingTimeInterval(Value.oneDayInSeconds)
        #expect(
            try DiaryOperations.diary(
                on: nextTokyoDay,
                context: context,
                calendar: tokyo
            ) == nil
        )
    }
}

private extension DiaryWidgetDayBoundaryTests {
    enum Value {
        static let middayHour = 12
        static let lateAfternoonHour = 15
        static let secondsPerMinute = 60
        static let minutesPerHour = 60
        static let hoursPerDay = 24
        static let tokyoOffsetHours = 9
        static let elapsedHours = 2

        static let secondsPerHour = secondsPerMinute * minutesPerHour
        static let tokyoOffsetSeconds = tokyoOffsetHours * secondsPerHour
        static let twoHoursInSeconds = TimeInterval(elapsedHours * secondsPerHour)
        static let oneDayInSeconds = TimeInterval(hoursPerDay * secondsPerHour)
        static let year = 2_026
        static let month = 9
        static let day = 21
    }

    static func calendar(secondsFromGMT: Int) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: secondsFromGMT) ?? .gmt
        return result
    }

    static func date(secondsFromGMT: Int, hour: Int) -> Date {
        let calendar = calendar(secondsFromGMT: secondsFromGMT)
        return calendar.date(
            from: .init(
                year: Value.year,
                month: Value.month,
                day: Value.day,
                hour: hour
            )
        ) ?? .init(timeIntervalSince1970: .zero)
    }
}
