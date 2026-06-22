import Foundation

/// Represents the current timer state within an active cooking session.
public enum CookingSessionTimerStatus: Equatable, Sendable {
    /// No timer is active.
    case inactive
    /// A timer is running with the remaining seconds.
    case running(remainingSeconds: Int)
    /// A timer reached its end.
    case expired
}
