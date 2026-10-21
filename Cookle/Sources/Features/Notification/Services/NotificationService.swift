import Combine
@preconcurrency import MHPlatform
import Observation
import SwiftData
import UIKit
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject {
    private enum SyncConstants {
        static let millisecondsPerSecond: TimeInterval = 1_000
        static let testSuggestionDelay: TimeInterval = 1
    }

    let routeInbox: MHObservableDeepLinkInbox
    let notificationCenter = UNUserNotificationCenter.current()
    let composer = RecipeSuggestionNotificationComposer()
    let syncWorker: NotificationSyncWorker
    let syncLogger: MHLogger
    let routeLogger: MHLogger

    private var lifecycleSynchronizationTask: Task<Void, Never>?
    private var isLifecycleSynchronizationPending = false

    let recordsUsage: Bool
    var usageObservers = Set<AnyCancellable>()
    var notificationOpenedThisForeground = false
    var activationBeforeRecording: (date: Date, state: AdaptiveRecipeSuggestionState)?
    var suggestionState: AdaptiveRecipeSuggestionState

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(
        modelContainer: ModelContainer,
        routeInbox: MHObservableDeepLinkInbox,
        syncLogger: MHLogger,
        routeLogger: MHLogger,
        recordsUsage: Bool = true
    ) {
        self.recordsUsage = recordsUsage
        self.suggestionState = recordsUsage
            ? AdaptiveRecipeSuggestionState.decoded(
                from: CooklePreferences.string(for: \.adaptiveRecipeSuggestionState)
            ) ?? .init()
            : .init()
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
        if recordsUsage {
            observeForegroundUsage()
        }
    }

    func scheduleLifecycleSynchronization() {
        _ = synchronizationTask()
    }

    func synchronizeScheduledSuggestions() async {
        await synchronizationTask().value
    }

    func applySuggestionSettings() async {
        await synchronizationTask().value
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

        await synchronizationTask().value
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
            identifier: CookleNotificationIdentifiers.testSuggestionIdentifier,
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
        if response.actionIdentifier == CookleNotificationIdentifiers.browseRecipesActionIdentifier {
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
            [NotificationConstants.suggestionCategoryDescriptor],
            center: notificationCenter
        )
    }

    func syncSuggestions() async {
        if await handleDisabledSuggestionSyncIfNeeded() {
            return
        }

        let status = await MHNotificationOrchestrator.requestAuthorizationIfNeeded(
            center: notificationCenter,
            options: authorizationOptions,
            requestIfNotDetermined: false
        )
        logAuthorizationRefresh(
            status: status,
            requestAuthorizationIfNeeded: false
        )

        if await handleUnauthorizedStatusIfNeeded(
            status: status
        ) {
            return
        }

        let plan: NotificationSyncWorker.Plan
        do {
            suggestionState = RecipeOperations.reconciledSuggestionState(suggestionState)
            saveSuggestionState()
            plan = try await syncWorker.buildPlan(
                state: suggestionState,
                mode: CooklePreferences.suggestionNotificationMode,
                hour: CooklePreferences.int(
                    for: \.dailyRecipeSuggestionHour,
                    default: DailySuggestionTimePolicy.defaultHour
                ),
                minute: CooklePreferences.int(for: \.dailyRecipeSuggestionMinute)
            )
        } catch {
            logPlanBuildFailure(error)
            return
        }
        // A foreground open or setting change during the worker await makes
        // this plan stale. The single synchronization loop will rebuild it.
        guard !isLifecycleSynchronizationPending else {
            return
        }
        logPlanBuilt(plan)
        await applyPlan(plan)
    }

    func replaceManagedSuggestionRequests(
        with requests: [UNNotificationRequest]
    ) async -> MHNotificationRequestSyncOutcome {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let managedRequests = pendingRequests.filter { request in
            CookleNotificationIdentifiers.isManagedSuggestion(
                identifier: request.identifier,
                contentKind: request.content.userInfo[NotificationConstants.contentKindUserInfoKey] as? String
            )
        }
        let managedIdentifiers = Set(managedRequests.map(\.identifier))

        return await MHNotificationOrchestrator.replaceManagedPendingRequests(
            center: notificationCenter,
            requests: requests
        ) { identifier in
            managedIdentifiers.contains(identifier)
        }
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) async {
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
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notifyDate
        )
        return .init(
            dateMatching: dateComponents,
            repeats: false
        )
    }

    private func synchronizationTask() -> Task<Void, Never> {
        isLifecycleSynchronizationPending = true
        if let lifecycleSynchronizationTask {
            return lifecycleSynchronizationTask
        }
        let task = Task { [weak self] in
            guard let self else {
                return
            }
            while isLifecycleSynchronizationPending {
                isLifecycleSynchronizationPending = false
                await syncSuggestions()
            }
            lifecycleSynchronizationTask = nil
        }
        lifecycleSynchronizationTask = task
        return task
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
