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
}

private extension CookleWidgetTimelineRefreshPolicyTests {
    func pacificCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(identifier: "America/Los_Angeles")
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
