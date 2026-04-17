import Observation
@preconcurrency import SwiftData

@MainActor
@Observable
final class SettingsActionService {
    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func prepareNotificationSettings() async {
        normalizeNotificationDefaultsIfNeeded()
        await notificationService.requestSettingsAuthorizationIfNeeded()
        await notificationService.synchronizeScheduledSuggestions()
    }

    func applyNotificationSettings() async {
        normalizeNotificationDefaultsIfNeeded()
        await notificationService.applySuggestionSettings()
    }

    func deleteAllData(modelContainer: ModelContainer) async throws {
        let mutationOutcome = try DataResetService.deleteAllWithOutcome(
            context: modelContainer.mainContext
        )

        if mutationOutcome.effects.contains(.diaryDataChanged) {
            CookleWidgetReloader.reloadTodayDiaryWidget()
        }

        if mutationOutcome.effects.contains(.recipeDataChanged) {
            CookleWidgetReloader.reloadRecipeWidgets()
        }

        if mutationOutcome.effects.contains(.notificationPlanChanged) {
            await notificationService.synchronizeScheduledSuggestions()
        }
    }
}

private extension SettingsActionService {
    func normalizeNotificationDefaultsIfNeeded() {
        if CooklePreferences.contains(\.dailyRecipeSuggestionHour) == false {
            CooklePreferences.set(
                DailySuggestionTimePolicy.defaultHour,
                for: \.dailyRecipeSuggestionHour
            )
        }

        if CooklePreferences.contains(\.dailyRecipeSuggestionMinute) == false {
            CooklePreferences.set(
                DailySuggestionTimePolicy.minimumTimeComponent,
                for: \.dailyRecipeSuggestionMinute
            )
        }
    }
}
