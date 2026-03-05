import Foundation

/// Canonical policy for daily recipe suggestion time handling.
public enum DailySuggestionTimePolicy {
    /// Lower bound for hour/minute components.
    public static let minimumTimeComponent = 0
    /// Default hour used when no value is stored.
    public static let defaultHour = 20
    /// Upper bound for hour component.
    public static let maximumHour = 23
    /// Upper bound for minute component.
    public static let maximumMinute = 59

    /// Clamps and normalizes hour/minute values.
    public static func normalized(
        hour: Int,
        minute: Int
    ) -> (hour: Int, minute: Int) {
        (
            clampedHour(hour),
            clampedMinute(minute)
        )
    }

    /// Clamps an hour into the allowed range.
    public static func clampedHour(_ hour: Int) -> Int {
        min(
            max(hour, minimumTimeComponent),
            maximumHour
        )
    }

    /// Clamps a minute into the allowed range.
    public static func clampedMinute(_ minute: Int) -> Int {
        min(
            max(minute, minimumTimeComponent),
            maximumMinute
        )
    }

    /// Builds a date for UI bindings from stored hour/minute values.
    public static func date(
        hour: Int,
        minute: Int,
        on anchorDate: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        let normalized = normalized(
            hour: hour,
            minute: minute
        )
        return calendar.date(
            bySettingHour: normalized.hour,
            minute: normalized.minute,
            second: 0,
            of: anchorDate
        ) ?? anchorDate
    }

    /// Extracts hour/minute components from a selected date.
    public static func components(
        from date: Date,
        calendar: Calendar = .current
    ) -> (hour: Int, minute: Int) {
        (
            calendar.component(.hour, from: date),
            calendar.component(.minute, from: date)
        )
    }
}
