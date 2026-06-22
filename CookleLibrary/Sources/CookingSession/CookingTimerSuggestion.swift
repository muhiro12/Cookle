import Foundation

/// Represents a timer suggestion inferred from a cooking step.
public struct CookingTimerSuggestion: Equatable, Sendable {
    /// The suggested duration in minutes.
    public let minutes: Int

    /// Creates a timer suggestion from the supplied minute value.
    public init(
        minutes: Int
    ) {
        self.minutes = max(minutes, .zero)
    }
}
