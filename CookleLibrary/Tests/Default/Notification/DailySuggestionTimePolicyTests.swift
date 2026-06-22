@testable import CookleLibrary
import Foundation
import Testing

struct DailySuggestionTimePolicyTests {
    @Test
    func normalized_clamps_out_of_range_components() {
        let normalized = DailySuggestionTimePolicy.normalized(
            hour: 99,
            minute: -10
        )

        #expect(normalized.hour == DailySuggestionTimePolicy.maximumHour)
        #expect(normalized.minute == DailySuggestionTimePolicy.minimumTimeComponent)
    }

    @Test
    func date_uses_normalized_components() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        let anchorDate = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 1,
                    day: 1,
                    hour: 12,
                    minute: 30
                )
            )
        )

        let suggestionDate = DailySuggestionTimePolicy.date(
            hour: 25,
            minute: 61,
            on: anchorDate,
            calendar: calendar
        )
        let dateComponents = calendar.dateComponents(
            [.hour, .minute],
            from: suggestionDate
        )

        #expect(dateComponents.hour == DailySuggestionTimePolicy.maximumHour)
        #expect(dateComponents.minute == DailySuggestionTimePolicy.maximumMinute)
    }

    @Test
    func components_extract_hour_and_minute() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
        let date = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 1,
                    day: 1,
                    hour: 7,
                    minute: 45
                )
            )
        )

        let components = DailySuggestionTimePolicy.components(
            from: date,
            calendar: calendar
        )

        #expect(components.hour == 7)
        #expect(components.minute == 45)
    }
}
