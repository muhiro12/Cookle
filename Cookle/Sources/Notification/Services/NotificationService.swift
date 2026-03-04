import SwiftData
import SwiftUI
import UserNotifications

@Observable
final class NotificationService: NSObject {
    private let modelContainer: ModelContainer
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current

    private let suggestionIdentifierPrefix = "daily-recipe-suggestion-"
    private let testSuggestionIdentifier = "daily-recipe-suggestion-test"
    private let suggestionThreadIdentifier = "daily-recipe-suggestion"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
        notificationCenter.delegate = self
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
                options: [.alert, .sound, .badge]
            )
            await refreshAuthorizationStatus()
        }

        guard isAuthorizationGranted else {
            return
        }

        let recipe = try? RecipeService.randomRecipe(
            context: modelContainer.mainContext
        )
        let content: UNMutableNotificationContent
        if let recipe {
            content = notificationContent(for: recipe)
            content.interruptionLevel = .active
        } else {
            content = fallbackNotificationContent(
                recipeName: String(localized: "Recipe"),
                interruptionLevel: .active
            )
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: testSuggestionIdentifier,
            content: content,
            trigger: trigger
        )
        try? await notificationCenter.add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_: UNUserNotificationCenter,
                                            willPresent _: UNNotification) async -> UNNotificationPresentationOptions { // swiftlint:disable:this async_without_await
        [.sound, .list, .banner]
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
        CooklePreferences.int(for: .dailyRecipeSuggestionHour, default: 20).clamped(to: 0...23)
    }

    var notificationMinute: Int {
        CooklePreferences.int(for: .dailyRecipeSuggestionMinute, default: 0).clamped(to: 0...59)
    }

    func syncSuggestions(requestAuthorizationIfNeeded: Bool) async {
        if !CooklePreferences.bool(for: .isDailyRecipeSuggestionNotificationOn) {
            await removeSuggestionRequests()
            await refreshAuthorizationStatus()
            return
        }

        await refreshAuthorizationStatus()

        if requestAuthorizationIfNeeded, authorizationStatus == .notDetermined {
            _ = try? await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await refreshAuthorizationStatus()
        }

        guard isAuthorizationGranted else {
            await removeSuggestionRequests()
            return
        }

        await removeSuggestionRequests()
        for request in buildDailySuggestionRequests() {
            try? await notificationCenter.add(request)
        }
    }

    func removeSuggestionRequests() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let suggestionIdentifiers = pendingRequests.compactMap { request in
            if request.identifier.hasPrefix(suggestionIdentifierPrefix)
                || request.identifier == testSuggestionIdentifier {
                return request.identifier
            }
            return nil
        }
        guard suggestionIdentifiers.isNotEmpty else {
            return
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: suggestionIdentifiers)
    }

    func buildDailySuggestionRequests(daysAhead: Int = 14) -> [UNNotificationRequest] {
        guard let recipes = try? modelContainer.mainContext.fetch(.recipes(.all)),
              recipes.isNotEmpty else {
            return []
        }

        let recipesByStableIdentifier = Dictionary(
            uniqueKeysWithValues: recipes.map { recipe in
                (
                    stableIdentifier(for: recipe),
                    recipe
                )
            }
        )

        let candidates = recipes.map { recipe in
            DailyRecipeSuggestionCandidate(
                name: recipe.name,
                stableIdentifier: stableIdentifier(for: recipe)
            )
        }
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: candidates,
            now: .now,
            calendar: calendar,
            hour: notificationHour,
            minute: notificationMinute,
            daysAhead: daysAhead,
            identifierPrefix: suggestionIdentifierPrefix
        )

        return suggestions.map { suggestion in
            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: suggestion.notifyDate
            )

            let content: UNMutableNotificationContent
            if let recipe = recipesByStableIdentifier[suggestion.stableIdentifier] {
                content = notificationContent(for: recipe)
            } else {
                content = fallbackNotificationContent(
                    recipeName: suggestion.recipeName,
                    interruptionLevel: .passive
                )
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            return UNNotificationRequest(
                identifier: suggestion.identifier,
                content: content,
                trigger: trigger
            )
        }
    }

    func notificationContent(for recipe: Recipe) -> UNMutableNotificationContent {
        let recipeName = recipeNotificationTitle(for: recipe)
        let content = UNMutableNotificationContent()
        content.title = recipeName
        content.body = RecipeBlurbService.makeBlurb(
            request: recipeBlurbRequest(for: recipe)
        ) ?? String(localized: "How about making \(recipeName) today?")
        content.sound = .default
        content.interruptionLevel = .passive
        content.threadIdentifier = suggestionThreadIdentifier
        return content
    }

    func fallbackNotificationContent(
        recipeName: String,
        interruptionLevel: UNNotificationInterruptionLevel
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Recipe Suggestion")
        content.body = String(localized: "How about making \(recipeName) today?")
        content.sound = .default
        content.interruptionLevel = interruptionLevel
        content.threadIdentifier = suggestionThreadIdentifier
        return content
    }

    func stableIdentifier(for recipe: Recipe) -> String {
        String(describing: recipe.persistentModelID)
    }

    func recipeBlurbRequest(for recipe: Recipe) -> RecipeBlurbRequest {
        let ingredientValues = recipe.ingredientObjects?.sorted().compactMap { object in
            object.ingredient?.value
        } ?? []
        return .init(
            steps: recipe.steps,
            ingredients: ingredientValues,
            note: recipe.note
        )
    }

    func recipeNotificationTitle(for recipe: Recipe) -> String {
        let trimmedName = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isNotEmpty ? trimmedName : String(localized: "Recipe")
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
