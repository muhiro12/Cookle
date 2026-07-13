import Foundation

/// Calendar-aware date policy for refreshing Cookle widgets.
public enum CookleWidgetTimelineRefreshPolicy {
    /// Returns the first moment of the calendar day after the given date.
    public static func startOfNextDay(
        after date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: date)
        )
    }
}
