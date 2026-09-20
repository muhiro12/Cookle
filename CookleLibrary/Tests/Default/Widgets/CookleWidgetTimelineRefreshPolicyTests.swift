@testable import CookleLibrary
import Foundation
import Testing

struct CookleWidgetTimelineRefreshPolicyTests {
    @Test
    func startOfNextDay_handles_spring_daylight_saving_transition() throws {
        let calendar = try pacificCalendar()
        let inputDate = try date(
            year: 2_026,
            month: 3,
            day: 8,
            hour: 12,
            calendar: calendar
        )
        let expectedDate = try date(
            year: 2_026,
            month: 3,
            day: 9,
            hour: 0,
            calendar: calendar
        )

        let refreshDate = try #require(
            CookleWidgetTimelineRefreshPolicy.startOfNextDay(
                after: inputDate,
                calendar: calendar
            )
        )

        #expect(refreshDate == expectedDate)
        #expect(
            refreshDate.timeIntervalSince(calendar.startOfDay(for: inputDate)) == 23 * 60 * 60
        )
    }

    @Test
    func startOfNextDay_handles_fall_daylight_saving_transition() throws {
        let calendar = try pacificCalendar()
        let inputDate = try date(
            year: 2_026,
            month: 11,
            day: 1,
            hour: 12,
            calendar: calendar
        )
        let expectedDate = try date(
            year: 2_026,
            month: 11,
            day: 2,
            hour: 0,
            calendar: calendar
        )

        let refreshDate = try #require(
            CookleWidgetTimelineRefreshPolicy.startOfNextDay(
                after: inputDate,
                calendar: calendar
            )
        )

        #expect(refreshDate == expectedDate)
        #expect(
            refreshDate.timeIntervalSince(calendar.startOfDay(for: inputDate)) == 25 * 60 * 60
        )
    }

    @Test
    func startOfNextDay_is_tied_to_the_calendar_it_was_computed_with() throws {
        let pacific = try pacificCalendar()
        let tokyo = try calendar(identifier: "Asia/Tokyo")
        let inputDate = try date(
            year: 2_026,
            month: 6,
            day: 1,
            hour: 12,
            calendar: pacific
        )

        let refreshDate = try #require(
            CookleWidgetTimelineRefreshPolicy.startOfNextDay(
                after: inputDate,
                calendar: pacific
            )
        )

        // The returned instant is midnight in the calendar it was computed with,
        // and is some other local time everywhere else. A widget timeline
        // scheduled before the device changes time zone therefore fires at the
        // wrong local moment until the next timeline request recomputes it.
        #expect(refreshDate == pacific.startOfDay(for: refreshDate))
        #expect(refreshDate != tokyo.startOfDay(for: refreshDate))
    }
}

private extension CookleWidgetTimelineRefreshPolicyTests {
    func pacificCalendar() throws -> Calendar {
        try calendar(identifier: "America/Los_Angeles")
    }

    func calendar(identifier timeZoneIdentifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(identifier: timeZoneIdentifier)
        )
        return calendar
    }

    func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(
            calendar.date(
                from: .init(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour
                )
            )
        )
    }
}
