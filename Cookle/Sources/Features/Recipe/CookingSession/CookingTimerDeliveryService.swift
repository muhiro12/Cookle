import ActivityKit
import Foundation
import MHPlatform
import Observation
import OSLog
import UIKit
import UserNotifications

/// Delivers the active cooking timer outside the app through one local
/// notification and one Live Activity.
///
/// Both are derived only from `CookingSessionStore`. Every store change and
/// every foreground activation schedules a reconciliation; a single loop
/// runs them in order and plans from the latest state after each
/// asynchronous step, so a slow permission prompt or request never restores
/// a timer that was cancelled or replaced meanwhile. Only this iPhone
/// schedules alerts; a change made on Watch reaches them once it is received.
@MainActor
@Observable
final class CookingTimerDeliveryService {
    /// What the app knows about the out-of-app alert for the current timer.
    enum NotificationStatus: Equatable {
        /// No running timer needs an alert, or delivery is off for this build.
        case idle
        /// A notification is scheduled for the running timer.
        case scheduled
        /// Notifications are turned off for Cookle.
        case disabled
        /// The notification could not be scheduled.
        case failed
    }

    private static let logger = Logger(subsystem: "Cookle", category: "CookingTimerDelivery")
    private static let notificationIdentifier = "cooking-timer"
    private static let timerKeyUserInfoKey = "cookingTimerKey"
    private static let contentKind = "cookingTimer"

    private(set) var notificationStatus: NotificationStatus = .idle

    @ObservationIgnored private let cookingSessionStore: CookingSessionStore
    @ObservationIgnored private let notificationCenter: UNUserNotificationCenter
    @ObservationIgnored private let isEnabled: Bool
    @ObservationIgnored private var reconciliationTask: Task<Void, Never>?
    @ObservationIgnored private var isReconciliationPending = false
    @ObservationIgnored private var requestsAuthorization = false
    @ObservationIgnored private var hasObservedTimer = false
    @ObservationIgnored private var lastObservedTimerKey: String?
    @ObservationIgnored private var activationObserver: (any NSObjectProtocol)?

    init(
        cookingSessionStore: CookingSessionStore,
        isEnabled: Bool,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.cookingSessionStore = cookingSessionStore
        self.notificationCenter = notificationCenter
        self.isEnabled = isEnabled
        guard isEnabled else {
            return
        }
        cookingSessionStore.setTimerDeliveryHandler { [weak self] isUserStartedTimer in
            self?.scheduleReconciliation(
                requestsAuthorization: isUserStartedTimer
            )
        }
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scheduleReconciliation(
                    requestsAuthorization: false
                )
            }
        }
        scheduleReconciliation(
            requestsAuthorization: false
        )
    }

    private static func isAuthorized(
        _ status: UNAuthorizationStatus
    ) -> Bool {
        switch status {
        case .authorized,
             .provisional,
             .ephemeral:
            return true
        case .denied,
             .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    // `Activity` is not `Sendable`, so each is looked up where it is used.
    @concurrent
    nonisolated private static func updateActivity(
        id: String,
        content: ActivityContent<CookingTimerActivityState>
    ) async {
        let activity = Activity<CookingTimerActivityAttributes>.activities.first { activity in
            activity.id == id
        }
        await activity?.update(content)
    }

    @concurrent
    nonisolated private static func endActivity(
        id: String
    ) async {
        let activity = Activity<CookingTimerActivityAttributes>.activities.first { activity in
            activity.id == id
        }
        await activity?.end(
            nil,
            dismissalPolicy: .immediate
        )
    }

    /// Queues a reconciliation with the latest cooking state.
    ///
    /// `requestsAuthorization` is `true` only for a timer the person started
    /// or repeated on this iPhone, the one moment Cookle asks for permission.
    func scheduleReconciliation(
        requestsAuthorization: Bool
    ) {
        guard isEnabled else {
            return
        }
        if requestsAuthorization {
            self.requestsAuthorization = true
        }
        isReconciliationPending = true
        guard reconciliationTask == nil else {
            return
        }
        reconciliationTask = Task { [weak self] in
            await self?.runReconciliationLoop()
        }
    }
}

private extension CookingTimerDeliveryService {
    var currentAlert: CookingTimerAlert? {
        CookingTimerAlert.current(
            in: cookingSessionStore.localState
        )
    }

    func runReconciliationLoop() async {
        while isReconciliationPending {
            isReconciliationPending = false
            let requestsAuthorization = requestsAuthorization
            self.requestsAuthorization = false
            await reconcileNotification(
                requestsAuthorization: requestsAuthorization
            )
            await reconcileActivities()
        }
        reconciliationTask = nil
    }

    // MARK: - Notification

    func reconcileNotification(
        requestsAuthorization: Bool
    ) async {
        let isAuthorized = Self.isAuthorized(
            await authorizationStatus(
                requestsAuthorization: requestsAuthorization
            )
        )
        let pendingTimerKey = await pendingTimerKey()
        let deliveredTimerKey = await deliveredTimerKey()

        // Plan from the state as it is now, after every await above.
        let alert = currentAlert
        let now = Date.now
        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: pendingTimerKey,
            deliveredTimerKey: deliveredTimerKey,
            isAuthorized: isAuthorized,
            now: now
        )
        if changes.removesPending {
            notificationCenter.removePendingNotificationRequests(
                withIdentifiers: [Self.notificationIdentifier]
            )
        }
        if changes.removesDelivered {
            notificationCenter.removeDeliveredNotifications(
                withIdentifiers: [Self.notificationIdentifier]
            )
        }

        guard let alert, alert.isRunning(at: now) else {
            notificationStatus = .idle
            return
        }
        guard isAuthorized else {
            notificationStatus = .disabled
            return
        }
        guard let scheduledAlert = changes.schedules else {
            notificationStatus = pendingTimerKey == alert.timerKey ? .scheduled : .failed
            return
        }
        do {
            try await notificationCenter.add(
                notificationRequest(for: scheduledAlert)
            )
            // A change during `add` has already queued another pass that
            // replaces or removes this request.
            notificationStatus = currentAlert?.timerKey == scheduledAlert.timerKey ? .scheduled : .idle
        } catch {
            Self.logger.error("Timer notification scheduling failed")
            notificationStatus = .failed
        }
    }

    /// Asks for permission only for a running timer the person just started
    /// and only when the choice has not been made yet.
    func authorizationStatus(
        requestsAuthorization: Bool
    ) async -> UNAuthorizationStatus {
        let status = await notificationCenter.notificationSettings().authorizationStatus
        guard requestsAuthorization,
              status == .notDetermined,
              currentAlert?.isRunning(at: .now) == true else {
            return status
        }
        do {
            _ = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .providesAppNotificationSettings]
            )
        } catch {
            Self.logger.error("Timer notification authorization request failed")
        }
        return await notificationCenter.notificationSettings().authorizationStatus
    }

    func pendingTimerKey() async -> String? {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.first { request in
            request.identifier == Self.notificationIdentifier
        }
        .flatMap { request in
            request.content.userInfo[Self.timerKeyUserInfoKey] as? String
        }
    }

    func deliveredTimerKey() async -> String? {
        let notifications = await notificationCenter.deliveredNotifications()
        return notifications.first { notification in
            notification.request.identifier == Self.notificationIdentifier
        }
        .flatMap { notification in
            notification.request.content.userInfo[Self.timerKeyUserInfoKey] as? String
        }
    }

    func notificationRequest(
        for alert: CookingTimerAlert
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = alert.recipeName
        content.subtitle = String(localized: "Timer Finished")
        content.body = String(
            localized: "Step \(alert.state.stepNumber) of \(alert.state.stepCount)"
        )
        content.sound = .default
        content.interruptionLevel = .active
        content.threadIdentifier = Self.notificationIdentifier
        content.targetContentIdentifier = "recipe:\(alert.recipeID)"
        var userInfo = NotificationConstants.payloadCodec.encode(
            .init(
                routes: .init(
                    defaultRouteURL: CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
                        for: alert.recipeID
                    ),
                    actionRouteURLs: [:]
                ),
                metadata: [
                    NotificationConstants.contentKindUserInfoKey: Self.contentKind,
                    NotificationConstants.stableIdentifierUserInfoKey: alert.recipeID
                ]
            )
        )
        userInfo[Self.timerKeyUserInfoKey] = alert.timerKey
        content.userInfo = userInfo
        return .init(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: max(alert.endsAt.timeIntervalSinceNow, 1),
                repeats: false
            )
        )
    }

    // MARK: - Live Activity

    func reconcileActivities() async {
        let alert = currentAlert
        // Only a timer first seen during this process counts as new, so a
        // relaunch reuses a surviving activity instead of recreating one the
        // person may have dismissed.
        let isNewTimer = hasObservedTimer
            && alert != nil
            && alert?.timerKey != lastObservedTimerKey
        let isActive = UIApplication.shared.applicationState == .active
        // While the app is inactive, such as behind the notification
        // permission prompt, a new timer stays new so the activation pass can
        // still start its activity.
        if isNewTimer == false || isActive {
            hasObservedTimer = true
            lastObservedTimerKey = alert?.timerKey
        }
        let allowsRequest = isNewTimer
            && isActive
            && ActivityAuthorizationInfo().areActivitiesEnabled

        let activities = Activity<CookingTimerActivityAttributes>.activities.filter { activity in
            activity.activityState == .active || activity.activityState == .stale
        }
        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: activities.map { activity in
                .init(
                    id: activity.id,
                    sessionKey: activity.attributes.sessionKey,
                    state: activity.content.state
                )
            },
            allowsRequest: allowsRequest,
            now: .now
        )
        for change in changes {
            await apply(change)
        }
    }

    func apply(
        _ change: CookingTimerDeliveryPlan.ActivityChange
    ) async {
        switch change {
        case .request(let alert):
            do {
                _ = try Activity.request(
                    attributes: CookingTimerActivityAttributes(
                        sessionKey: alert.sessionKey,
                        recipeID: alert.recipeID,
                        recipeName: alert.recipeName
                    ),
                    content: activityContent(for: alert),
                    pushType: nil
                )
            } catch {
                Self.logger.error("Timer Live Activity request failed")
            }
        case let .update(id, alert):
            await Self.updateActivity(
                id: id,
                content: activityContent(for: alert)
            )
        case .end(let id):
            await Self.endActivity(
                id: id
            )
        }
    }

    func activityContent(
        for alert: CookingTimerAlert
    ) -> ActivityContent<CookingTimerActivityState> {
        .init(
            state: alert.state,
            staleDate: alert.endsAt
        )
    }
}
