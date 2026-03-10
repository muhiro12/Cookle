@preconcurrency import MHPlatform
import Observation
import SwiftData
import UserNotifications

@Observable
final class NotificationService: NSObject {
    private enum SyncConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
        static let testSuggestionDelay = TimeInterval(
            Int("1") ?? .zero
        )
    }

    private let routeInbox: MHObservableDeepLinkInbox
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    private let composer = RecipeSuggestionNotificationComposer()
    private let syncWorker: NotificationSyncWorker
    private let syncLogger = CookleApp.logger(
        category: "NotificationSync",
        source: #fileID
    )

    @MainActor private var lifecycleSynchronizationTask: Task<Void, Never>?
    @MainActor private var isLifecycleSynchronizationPending = false

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(
        modelContainer: ModelContainer,
        routeInbox: MHObservableDeepLinkInbox
    ) {
        self.routeInbox = routeInbox
        self.syncWorker = .init(
            modelContainer: modelContainer
        )
        super.init()
        notificationCenter.delegate = self
        registerNotificationCategories()
    }

    @MainActor
    func scheduleLifecycleSynchronization() {
        isLifecycleSynchronizationPending = true
        guard lifecycleSynchronizationTask == nil else {
            return
        }

        lifecycleSynchronizationTask = Task { [weak self] in
            guard let self else {
                return
            }
            await runLifecycleSynchronizationLoop()
        }
    }

    func synchronizeScheduledSuggestions() async {
        await syncSuggestions(requestAuthorizationIfNeeded: false)
    }

    func applySuggestionSettings() async {
        await syncSuggestions(requestAuthorizationIfNeeded: true)
    }

    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
        }
    }

    func sendTestSuggestionNotification() async {
        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions
        )
        authorizationStatus = status

        guard isAuthorizationGranted else {
            return
        }

        let snapshot = await syncWorker.randomRecipeSnapshot()
        let attachmentFileURL: URL? = if let snapshot {
            await syncWorker.prepareAttachmentFileURL(
                for: snapshot
            )
        } else {
            nil
        }
        let content = snapshot.map { resolvedSnapshot in
            composer.content(
                for: resolvedSnapshot,
                attachmentFileURL: attachmentFileURL
            )
        } ?? composer.fallbackContent(
            recipeName: String(localized: "Recipe")
        )

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: SyncConstants.testSuggestionDelay,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: NotificationConstants.testSuggestionIdentifier,
            content: content,
            trigger: trigger
        )
        try? await notificationCenter.add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await Task.yield()
        return [.sound, .list, .banner]
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        await handleNotificationResponse(response)
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter,
                                            openSettingsFor _: UNNotification?) {
        let settingsURL = CookleDeepLinkURLBuilder.preferredURL(for: .settings)
        Task { @MainActor in
            let notificationLogger = CookleApp.logger(
                category: "NotificationRoute",
                source: #fileID
            )
            notificationLogger.info("notification settings route requested")
            await routeInbox.replacePendingURL(settingsURL)
        }
    }
}

private extension NotificationService {
    var isAuthorizationGranted: Bool {
        switch authorizationStatus {
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

    var notificationHour: Int {
        let suggestionTime = DailySuggestionTimePolicy.normalized(
            hour: CooklePreferences.int(
                for: .dailyRecipeSuggestionHour,
                default: DailySuggestionTimePolicy.defaultHour
            ),
            minute: CooklePreferences.int(
                for: .dailyRecipeSuggestionMinute,
                default: DailySuggestionTimePolicy.minimumTimeComponent
            )
        )
        return suggestionTime.hour
    }

    var notificationMinute: Int {
        let suggestionTime = DailySuggestionTimePolicy.normalized(
            hour: CooklePreferences.int(
                for: .dailyRecipeSuggestionHour,
                default: DailySuggestionTimePolicy.defaultHour
            ),
            minute: CooklePreferences.int(
                for: .dailyRecipeSuggestionMinute,
                default: DailySuggestionTimePolicy.minimumTimeComponent
            )
        )
        return suggestionTime.minute
    }

    var authorizationOptions: UNAuthorizationOptions {
        [
            .alert,
            .sound,
            .providesAppNotificationSettings
        ]
    }

    nonisolated static func fallbackRouteURL(
        _: MHNotificationPayload?,
        response: MHNotificationResponseContext
    ) -> URL? {
        if response.actionIdentifier == NotificationConstants.browseRecipesActionIdentifier {
            return CookleDeepLinkURLBuilder.preferredRecipeURL()
        }

        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            return CookleDeepLinkURLBuilder.preferredRecipeURL()
        }

        return nil
    }

    func registerNotificationCategories() {
        MHNotificationOrchestrator.registerCategories(
            [
                NotificationConstants.suggestionCategoryDescriptor
            ],
            center: notificationCenter
        )
    }

    func syncSuggestions(requestAuthorizationIfNeeded: Bool) async {
        if !CooklePreferences.bool(for: .isDailyRecipeSuggestionNotificationOn) {
            await replaceManagedSuggestionRequests(with: [])
            await syncWorker.removeAllAttachments()
            await refreshAuthorizationStatus()
            return
        }

        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions,
            requestIfNotDetermined: requestAuthorizationIfNeeded
        )
        authorizationStatus = status

        guard isAuthorizationGranted else {
            await replaceManagedSuggestionRequests(with: [])
            await syncWorker.removeAllAttachments()
            return
        }

        let plan = await syncWorker.buildPlan(
            hour: notificationHour,
            minute: notificationMinute
        )
        let requestApplyStartedAt = Date.timeIntervalSinceReferenceDate
        await replaceManagedSuggestionRequests(
            with: plan.preparedRequests.map(suggestionRequest)
        )
        syncLogger.notice(
            "request apply finished in \(durationMilliseconds(since: requestApplyStartedAt)) ms"
        )
    }

    func replaceManagedSuggestionRequests(
        with requests: [UNNotificationRequest]
    ) async {
        let isManagedIdentifier: @Sendable (String) -> Bool = { identifier in
            identifier.hasPrefix(NotificationConstants.suggestionIdentifierPrefix)
                || identifier == NotificationConstants.testSuggestionIdentifier
        }

        _ = await MHNotificationOrchestrator.replaceManagedPendingRequests(
            center: notificationCenter,
            requests: requests,
            isManagedIdentifier: isManagedIdentifier
        )
    }

    nonisolated func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let notificationLogger = CookleApp.logger(
            category: "NotificationRoute",
            source: #fileID
        )
        let payload = NotificationConstants.payloadCodec.decode(
            response.notification.request.content.userInfo
        )
        let responseContext = MHNotificationResponseContext(
            actionIdentifier: response.actionIdentifier
        )
        let routeDestination = await MainActor.run {
            routeInbox
        }
        let deliveredOutcome = await MHNotificationOrchestrator.deliverRouteURL(
            payload: payload,
            response: responseContext,
            destination: routeDestination,
            fallbackRouteURL: Self.fallbackRouteURL
        )

        switch deliveredOutcome.source {
        case .payload:
            notificationLogger.info("notification route resolved")
        case .fallback where response.actionIdentifier
                == NotificationConstants.browseRecipesActionIdentifier:
            notificationLogger.notice("notification route resolved via browse fallback")
        case .fallback where response.actionIdentifier == UNNotificationDefaultActionIdentifier:
            notificationLogger.info("notification route resolved via default fallback")
        case .fallback:
            notificationLogger.info("notification route resolved via fallback")
        case .noRoute:
            notificationLogger.info("notification route resolution returned no route")
        }
    }

    func suggestionRequest(
        _ preparedRequest: NotificationSyncWorker.PreparedSuggestionRequest
    ) -> UNNotificationRequest {
        let content: UNMutableNotificationContent
        if let snapshot = preparedRequest.snapshot {
            content = composer.content(
                for: snapshot,
                attachmentFileURL: preparedRequest.attachmentFileURL
            )
        } else {
            content = composer.fallbackContent(
                recipeName: preparedRequest.suggestion.recipeName,
                stableIdentifier: preparedRequest.suggestion.stableIdentifier
            )
        }

        return .init(
            identifier: preparedRequest.suggestion.identifier,
            content: content,
            trigger: suggestionTrigger(
                for: preparedRequest.suggestion.notifyDate
            )
        )
    }

    func suggestionTrigger(for notifyDate: Date) -> UNCalendarNotificationTrigger {
        let dateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notifyDate
        )
        return .init(
            dateMatching: dateComponents,
            repeats: false
        )
    }

    @MainActor
    func runLifecycleSynchronizationLoop() async {
        while isLifecycleSynchronizationPending {
            isLifecycleSynchronizationPending = false
            await synchronizeScheduledSuggestions()
        }

        lifecycleSynchronizationTask = nil
    }

    func durationMilliseconds(
        since startedAt: TimeInterval
    ) -> Int {
        Int(
            (
                Date.timeIntervalSinceReferenceDate
                    - startedAt
            ) * SyncConstants.millisecondsPerSecond
        )
    }
}
