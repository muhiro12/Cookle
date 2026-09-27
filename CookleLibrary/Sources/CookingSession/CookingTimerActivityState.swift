import Foundation

/// The dynamic content of the cooking timer Live Activity.
///
/// It carries only dates and step positions so the system can count down to
/// the deadline without the app running.
public struct CookingTimerActivityState: Codable, Hashable, Sendable {
    /// The time the timer started.
    public let timerStartedAt: Date
    /// The time the timer reaches zero.
    public let timerEndsAt: Date
    /// The one-based number of the current step.
    public let stepNumber: Int
    /// The number of steps in the recipe.
    public let stepCount: Int

    public init(
        timerStartedAt: Date,
        timerEndsAt: Date,
        stepNumber: Int,
        stepCount: Int
    ) {
        self.timerStartedAt = timerStartedAt
        self.timerEndsAt = timerEndsAt
        self.stepNumber = stepNumber
        self.stepCount = stepCount
    }
}
