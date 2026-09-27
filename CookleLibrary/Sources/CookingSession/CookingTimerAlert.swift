import Foundation

/// The system-facing description of the timer in the active cooking session.
///
/// It is derived only from existing cooking session state. The session key
/// identifies the session that owns a Live Activity; the timer key changes
/// whenever a timer starts, repeats, or is replaced, so an alert for an
/// earlier timer is never mistaken for the current one.
public struct CookingTimerAlert: Equatable, Sendable {
    /// Identifies the cooking session that owns the timer.
    public let sessionKey: String
    /// Identifies this timer run within the session.
    public let timerKey: String
    /// The stable identifier of the recipe being cooked.
    public let recipeID: String
    /// The recipe name shown by the alert.
    public let recipeName: String
    /// The timer and step progress shown by a Live Activity.
    public let state: CookingTimerActivityState

    /// The time the timer reaches zero.
    public var endsAt: Date {
        state.timerEndsAt
    }

    public init(
        sessionKey: String,
        timerKey: String,
        recipeID: String,
        recipeName: String,
        state: CookingTimerActivityState
    ) {
        self.sessionKey = sessionKey
        self.timerKey = timerKey
        self.recipeID = recipeID
        self.recipeName = recipeName
        self.state = state
    }

    /// Returns the alert for the active session's timer, or `nil` when no
    /// live session has a timer. An expired timer still returns its alert so
    /// callers can keep its delivered notification until the user acts.
    public static func current(
        in state: CookingSessionLocalState
    ) -> Self? {
        guard let record = state.activeRecord,
              let timer = record.snapshot.activeTimer,
              timer.startedAt.timeIntervalSinceReferenceDate.isFinite,
              timer.endsAt.timeIntervalSinceReferenceDate.isFinite,
              timer.endsAt > timer.startedAt else {
            return nil
        }
        let recordSessionKey = "\(record.sessionID.originID).\(record.sessionID.sequence)"
        let startBits = timer.startedAt.timeIntervalSinceReferenceDate.bitPattern
        return .init(
            sessionKey: recordSessionKey,
            timerKey: "\(recordSessionKey).\(startBits).\(timer.durationSeconds)",
            recipeID: record.snapshot.recipeID,
            recipeName: record.snapshot.recipeName,
            state: .init(
                timerStartedAt: timer.startedAt,
                timerEndsAt: timer.endsAt,
                stepNumber: record.snapshot.currentStepNumber,
                stepCount: record.snapshot.stepCount
            )
        )
    }

    /// Whether the timer is still counting down at `date`.
    public func isRunning(
        at date: Date
    ) -> Bool {
        endsAt > date
    }
}
