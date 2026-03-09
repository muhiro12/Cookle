import MHDeepLinking
@preconcurrency import MHNotificationPayloads
import SwiftData
import SwiftUI
import UserNotifications

@Observable
final class NotificationService: NSObject {
    private struct ScheduledSuggestionRequest {
        let request: UNNotificationRequest
        let stableIdentifier: String
        let hasAttachment: Bool
    }

    private let modelContainer: ModelContainer
    private let routeInbox: MHObservableDeepLinkInbox
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    private let attachmentStore: NotificationAttachmentStore
    private let composer: RecipeSuggestionNotificationComposer

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(
        modelContainer: ModelContainer,
        routeInbox: MHObservableDeepLinkInbox
    ) {
        self.modelContainer = modelContainer
        self.routeInbox = routeInbox
        let attachmentStore = NotificationAttachmentStore()
        self.attachmentStore = attachmentStore
        self.composer = .init(attachmentStore: attachmentStore)
        super.init()
        notificationCenter.delegate = self
        registerNotificationCategories()
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

        let recipe = try? RecipeService.randomRecipe(
            context: modelContainer.mainContext
        )
        let content = recipe.map { resolvedRecipe in
            composer.content(
                for: resolvedRecipe,
                stableIdentifier: stableIdentifier(for: resolvedRecipe)
            )
        } ?? composer.fallbackContent(
            recipeName: String(localized: "Recipe")
        )

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
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
            attachmentStore.removeAllAttachments()
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
            attachmentStore.removeAllAttachments()
            return
        }

        let scheduledRequests = buildDailySuggestionRequests()
        attachmentStore.pruneAttachments(
            keepingStableIdentifiers: Set(
                scheduledRequests.compactMap { scheduledRequest in
                    if scheduledRequest.hasAttachment {
                        return scheduledRequest.stableIdentifier
                    }
                    return nil
                }
            )
        )
        await replaceManagedSuggestionRequests(
            with: scheduledRequests.map(\.request)
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

    private func buildDailySuggestionRequests(daysAhead: Int = 14) -> [ScheduledSuggestionRequest] {
        guard let recipes = try? modelContainer.mainContext.fetch(.recipes(.all)),
              recipes.isNotEmpty else {
            return []
        }

        let recipesByStableIdentifier = recipeMapByStableIdentifier(from: recipes)
        let candidates = suggestionCandidates(from: recipes)
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: candidates,
            hour: notificationHour,
            minute: notificationMinute,
            now: .now,
            calendar: calendar,
            daysAhead: daysAhead,
            identifierPrefix: NotificationConstants.suggestionIdentifierPrefix
        )

        return suggestions.map { suggestion in
            let content = suggestionContent(
                for: suggestion,
                recipesByStableIdentifier: recipesByStableIdentifier
            )
            return ScheduledSuggestionRequest(
                request: UNNotificationRequest(
                    identifier: suggestion.identifier,
                    content: content,
                    trigger: suggestionTrigger(for: suggestion.notifyDate)
                ),
                stableIdentifier: suggestion.stableIdentifier,
                hasAttachment: content.attachments.isEmpty == false
            )
        }
    }

    nonisolated func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let notificationLogger = CookleApp.logger(
            category: "NotificationRoute",
            source: #fileID
        )
        let outcome = MHNotificationOrchestrator.routeDeliveryOutcome(
            userInfo: response.notification.request.content.userInfo,
            actionIdentifier: response.actionIdentifier,
            codec: NotificationConstants.payloadCodec,
            fallbackRouteURL: Self.fallbackRouteURL
        )
        let deliveredOutcome = await MHNotificationOrchestrator.deliverRouteURL(
            outcome,
            deliver: routeInbox.replacePendingURL
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

    func stableIdentifier(for recipe: Recipe) -> String {
        RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )
    }

    func recipeMapByStableIdentifier(from recipes: [Recipe]) -> [String: Recipe] {
        Dictionary(
            uniqueKeysWithValues: recipes.map { recipe in
                (
                    stableIdentifier(for: recipe),
                    recipe
                )
            }
        )
    }

    func suggestionCandidates(from recipes: [Recipe]) -> [DailyRecipeSuggestionCandidate] {
        recipes.map { recipe in
            .init(
                name: recipe.name,
                stableIdentifier: stableIdentifier(for: recipe)
            )
        }
    }

    func suggestionContent(
        for suggestion: DailyRecipeSuggestion,
        recipesByStableIdentifier: [String: Recipe]
    ) -> UNMutableNotificationContent {
        if let recipe = recipesByStableIdentifier[suggestion.stableIdentifier] {
            return composer.content(
                for: recipe,
                stableIdentifier: suggestion.stableIdentifier
            )
        }
        return composer.fallbackContent(
            recipeName: suggestion.recipeName,
            stableIdentifier: suggestion.stableIdentifier
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
}
