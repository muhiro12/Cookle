import Foundation

/// Pure reconciliation rules for the cooking timer's local notification and
/// Live Activity.
///
/// Callers read the system's current requests and activities, then apply the
/// returned changes. Planning from the latest cooking state after every
/// asynchronous step keeps a delayed result from restoring a cancelled or
/// replaced timer.
public enum CookingTimerDeliveryPlan {
    /// The changes needed to make the one managed timer notification match
    /// the current timer.
    public struct NotificationChanges: Equatable, Sendable {
        /// Whether the pending request must be removed.
        public let removesPending: Bool
        /// Whether the delivered notification must be removed.
        public let removesDelivered: Bool
        /// The alert to schedule, replacing any pending request.
        public let schedules: CookingTimerAlert?

        public init(
            removesPending: Bool,
            removesDelivered: Bool,
            schedules: CookingTimerAlert?
        ) {
            self.removesPending = removesPending
            self.removesDelivered = removesDelivered
            self.schedules = schedules
        }
    }

    /// A Live Activity the system currently shows for this app.
    public struct ActivityRecord: Equatable, Sendable {
        /// The system identifier of the activity.
        public let id: String
        /// The cooking session the activity belongs to.
        public let sessionKey: String
        /// The content the activity currently shows.
        public let state: CookingTimerActivityState

        public init(
            id: String,
            sessionKey: String,
            state: CookingTimerActivityState
        ) {
            self.id = id
            self.sessionKey = sessionKey
            self.state = state
        }
    }

    /// One change to apply to the app's Live Activities.
    public enum ActivityChange: Equatable, Sendable {
        /// Start an activity for the alert.
        case request(CookingTimerAlert)
        /// Show the alert's content in an existing activity.
        case update(id: String, alert: CookingTimerAlert)
        /// End an activity immediately.
        case end(id: String)
    }

    /// Plans the managed notification.
    ///
    /// Only a running timer is scheduled, so a timer that already expired
    /// while the app was not running never produces a fresh overdue alert.
    /// A delivered notification stays while its timer remains current and is
    /// removed once the timer is cancelled, replaced, or its session ends.
    public static func notificationChanges(
        for alert: CookingTimerAlert?,
        pendingTimerKey: String?,
        deliveredTimerKey: String?,
        isAuthorized: Bool,
        now: Date
    ) -> NotificationChanges {
        let scheduledAlert: CookingTimerAlert? = if let alert,
                                                    isAuthorized,
                                                    alert.isRunning(at: now) {
            alert
        } else {
            nil
        }
        let removesPending = pendingTimerKey != nil
            && pendingTimerKey != scheduledAlert?.timerKey
        let removesDelivered = deliveredTimerKey != nil
            && deliveredTimerKey != alert?.timerKey
        let schedules = scheduledAlert?.timerKey == pendingTimerKey
            ? nil
            : scheduledAlert
        return .init(
            removesPending: removesPending,
            removesDelivered: removesDelivered,
            schedules: schedules
        )
    }

    /// Plans Live Activity changes.
    ///
    /// An existing activity for the current session is reused and updated;
    /// duplicates and activities for other sessions end. A new activity is
    /// requested only when the caller allows it, which it does for a newly
    /// started timer while the app is in the foreground. Step changes
    /// therefore never bring back an activity the person dismissed.
    public static func activityChanges(
        for alert: CookingTimerAlert?,
        existing activities: [ActivityRecord],
        allowsRequest: Bool,
        now: Date
    ) -> [ActivityChange] {
        guard let alert else {
            return activities.map { activity in
                .end(id: activity.id)
            }
        }

        var changes: [ActivityChange] = activities
            .filter { activity in
                activity.sessionKey != alert.sessionKey
            }
            .map { activity in
                .end(id: activity.id)
            }
        let matchingActivities = activities.filter { activity in
            activity.sessionKey == alert.sessionKey
        }
        if let reusedActivity = matchingActivities.first {
            changes += matchingActivities.dropFirst().map { activity in
                .end(id: activity.id)
            }
            if reusedActivity.state != alert.state {
                changes.append(
                    .update(id: reusedActivity.id, alert: alert)
                )
            }
        } else if allowsRequest,
                  alert.isRunning(at: now) {
            changes.append(.request(alert))
        }
        return changes
    }
}
