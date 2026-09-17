@preconcurrency import MHPlatform
import Observation
import SwiftData
import UserNotifications

@Observable
final class NotificationService: NSObject {
    private enum SyncConstants {
        static let millisecondsPerSecond: TimeInterval = 1_000
        static let testSuggestionDelay: TimeInterval = 1
    }

    let routeInbox: MHObservableDeepLinkInbox
    let notificationCenter = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    let composer = RecipeSuggestionNotificationComposer()
    let syncWorker: NotificationSyncWorker
    let syncLogger: MHLogger
    let routeLogger: MHLogger

    @MainActor private var lifecycleSynchronizationTask: Task<Void, Never>?
    @MainActor private var isLifecycleSynchronizationPending = false

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(
        modelContainer: ModelContainer,
        routeInbox: MHObservableDeepLinkInbox,
        syncLogger: MHLogger,
        routeLogger: MHLogger
    ) {
        self.routeInbox = routeInbox
        self.syncLogger = syncLogger
        self.routeLogger = routeLogger
        self.syncWorker = .init(
            modelContainer: modelContainer,
            logger: syncLogger
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

    func requestSettingsAuthorizationIfNeeded() async {
        await refreshAuthorizationStatus()

        guard authorizationStatus == .notDetermined else {
            return
        }

        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions,
            requestIfNotDetermined: true
        )
        logAuthorizationRefresh(
            status: status,
            requestAuthorizationIfNeeded: true
        )

        if isAuthorizationGranted(status) {
            CooklePreferences.set(
                true,
                for: \.isDailyRecipeSuggestionNotificationOn
            )
            return
        }

        CooklePreferences.set(
            false,
            for: \.isDailyRecipeSuggestionNotificationOn
        )
        await clearSuggestionsAndAttachments()
    }

    func refreshAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
        }
    }

    func sendTestSuggestionNotification() async throws {
        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions
        )
        authorizationStatus = status

        guard isAuthorizationGranted else {
            return
        }

        let snapshot = try await testSuggestionSnapshot()
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
        do {
            try await notificationCenter.add(request)
        } catch {
            logTestSuggestionFailure(
                error,
                stage: "request_add"
            )
            throw error
        }
    }
}

extension NotificationService {
    var isAuthorizationGranted: Bool {
        isAuthorizationGranted(
            authorizationStatus
        )
    }

    var notificationHour: Int {
        let suggestionTime = DailySuggestionTimePolicy.normalized(
            hour: CooklePreferences.int(
                for: \.dailyRecipeSuggestionHour,
                default: DailySuggestionTimePolicy.defaultHour
            ),
            minute: CooklePreferences.int(
                for: \.dailyRecipeSuggestionMinute,
                default: DailySuggestionTimePolicy.minimumTimeComponent
            )
        )
        return suggestionTime.hour
    }

    var notificationMinute: Int {
        let suggestionTime = DailySuggestionTimePolicy.normalized(
            hour: CooklePreferences.int(
                for: \.dailyRecipeSuggestionHour,
                default: DailySuggestionTimePolicy.defaultHour
            ),
            minute: CooklePreferences.int(
                for: \.dailyRecipeSuggestionMinute,
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

    func testSuggestionSnapshot() async throws -> NotificationRecipeSnapshot? {
        do {
            return try await syncWorker.randomRecipeSnapshot()
        } catch {
            logTestSuggestionFailure(
                error,
                stage: "snapshot_fetch"
            )
            throw error
        }
    }

    func isAuthorizationGranted(
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

    func registerNotificationCategories() {
        MHNotificationOrchestrator.registerCategories(
            [
                NotificationConstants.suggestionCategoryDescriptor
            ],
            center: notificationCenter
        )
    }

    func syncSuggestions(requestAuthorizationIfNeeded: Bool) async {
        if await handleDisabledSuggestionSyncIfNeeded() {
            return
        }

        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions,
            requestIfNotDetermined: requestAuthorizationIfNeeded
        )
        logAuthorizationRefresh(
            status: status,
            requestAuthorizationIfNeeded: requestAuthorizationIfNeeded
        )

        if await handleUnauthorizedStatusIfNeeded(
            status: status
        ) {
            return
        }

        let plan: NotificationSyncWorker.Plan
        do {
            plan = try await syncWorker.buildPlan(
                hour: notificationHour,
                minute: notificationMinute
            )
        } catch {
            logPlanBuildFailure(error)
            return
        }
        logPlanBuilt(plan)
        await applyPlan(plan)
    }

    func replaceManagedSuggestionRequests(
        with requests: [UNNotificationRequest]
    ) async -> MHNotificationRequestSyncOutcome {
        let isManagedIdentifier: @Sendable (String) -> Bool = { identifier in
            identifier.hasPrefix(NotificationConstants.suggestionIdentifierPrefix)
                || identifier == NotificationConstants.testSuggestionIdentifier
        }

        return await MHNotificationOrchestrator.replaceManagedPendingRequests(
            center: notificationCenter,
            requests: requests,
            isManagedIdentifier: isManagedIdentifier
        )
    }

    nonisolated func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let deliveredOutcome = await deliverRoute(
            for: response
        )
        logRouteDeliveryOutcome(
            deliveredOutcome,
            response: response
        )
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
