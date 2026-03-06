import SwiftData
import SwiftUI
import UserNotifications

@Observable
final class NotificationService: NSObject {
    private let modelContainer: ModelContainer
    private let routeInbox: MainRouteInbox
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    private let attachmentStore: NotificationAttachmentStore
    private let composer: RecipeSuggestionNotificationComposer

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(
        modelContainer: ModelContainer,
        routeInbox: MainRouteInbox
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
        await refreshAuthorizationStatus()

        if authorizationStatus == .notDetermined {
            _ = try? await notificationCenter.requestAuthorization(
                options: authorizationOptions
            )
            await refreshAuthorizationStatus()
        }

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
            routeInbox.store(settingsURL)
        }
    }
}

private extension NotificationService {
    struct ScheduledSuggestionRequest {
        let request: UNNotificationRequest
        let stableIdentifier: String
        let hasAttachment: Bool
    }

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

    func registerNotificationCategories() {
        let browseRecipesAction = UNNotificationAction(
            identifier: NotificationConstants.browseRecipesActionIdentifier,
            title: "Browse Recipes",
            options: [.foreground]
        )
        let suggestionCategory = UNNotificationCategory(
            identifier: NotificationConstants.suggestionCategoryIdentifier,
            actions: [browseRecipesAction],
            intentIdentifiers: []
        )
        notificationCenter.setNotificationCategories([suggestionCategory])
    }

    func syncSuggestions(requestAuthorizationIfNeeded: Bool) async {
        if !CooklePreferences.bool(for: .isDailyRecipeSuggestionNotificationOn) {
            await removeSuggestionRequests()
            attachmentStore.removeAllAttachments()
            await refreshAuthorizationStatus()
            return
        }

        await refreshAuthorizationStatus()

        if requestAuthorizationIfNeeded, authorizationStatus == .notDetermined {
            _ = try? await notificationCenter.requestAuthorization(
                options: authorizationOptions
            )
            await refreshAuthorizationStatus()
        }

        guard isAuthorizationGranted else {
            await removeSuggestionRequests()
            attachmentStore.removeAllAttachments()
            return
        }

        await removeSuggestionRequests()
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
        for scheduledRequest in scheduledRequests {
            try? await notificationCenter.add(scheduledRequest.request)
        }
    }

    func removeSuggestionRequests() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let suggestionIdentifiers = pendingRequests.compactMap { request in
            if request.identifier.hasPrefix(NotificationConstants.suggestionIdentifierPrefix)
                || request.identifier == NotificationConstants.testSuggestionIdentifier {
                return request.identifier
            }
            return nil
        }
        guard suggestionIdentifiers.isNotEmpty else {
            return
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: suggestionIdentifiers)
    }

    func buildDailySuggestionRequests(daysAhead: Int = 14) -> [ScheduledSuggestionRequest] {
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
        guard let routeURL = routeURL(for: response) else {
            return
        }
        await MainActor.run {
            routeInbox.store(routeURL)
        }
    }

    nonisolated func routeURL(for response: UNNotificationResponse) -> URL? {
        switch response.actionIdentifier {
        case NotificationConstants.browseRecipesActionIdentifier:
            return CookleDeepLinkURLBuilder.preferredRecipeURL()
        case UNNotificationDefaultActionIdentifier:
            return routeURL(
                from: response.notification.request.content.userInfo
            ) ?? CookleDeepLinkURLBuilder.preferredRecipeURL()
        case UNNotificationDismissActionIdentifier:
            return nil
        default:
            return nil
        }
    }

    nonisolated func routeURL(from userInfo: [AnyHashable: Any]) -> URL? {
        guard let routeURLString = userInfo[
            NotificationConstants.routeURLUserInfoKey
        ] as? String else {
            return nil
        }
        return .init(string: routeURLString)
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
