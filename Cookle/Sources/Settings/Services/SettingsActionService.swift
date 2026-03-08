import MHPlatform
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
        await notificationService.refreshAuthorizationStatus()
        await notificationService.synchronizeScheduledSuggestions()
    }

    func applyNotificationSettings() async {
        normalizeNotificationDefaultsIfNeeded()
        await notificationService.applySuggestionSettings()
    }

    func deleteAllData(context: ModelContext) async throws {
        _ = try await MHDestructiveResetService.runThrowing(
            steps: [
                .init(name: "deleteAllData") {
                    try await MainActor.run {
                        try DataResetService.deleteAll(context: context)
                    }
                },
                .init(name: "reloadTodayDiaryWidget") {
                    await MainActor.run {
                        CookleWidgetReloader.reloadTodayDiaryWidget()
                    }
                },
                .init(name: "reloadRecipeWidgets") {
                    await MainActor.run {
                        CookleWidgetReloader.reloadRecipeWidgets()
                    }
                },
                .init(name: "synchronizeScheduledSuggestions") { [self] in
                    await notificationService.synchronizeScheduledSuggestions()
                }
            ]
        )
    }
}

private extension SettingsActionService {
    func normalizeNotificationDefaultsIfNeeded() {
        if CooklePreferences.contains(.dailyRecipeSuggestionHour) == false {
            CooklePreferences.set(
                DailySuggestionTimePolicy.defaultHour,
                for: .dailyRecipeSuggestionHour
            )
        }

        if CooklePreferences.contains(.dailyRecipeSuggestionMinute) == false {
            CooklePreferences.set(
                DailySuggestionTimePolicy.minimumTimeComponent,
                for: .dailyRecipeSuggestionMinute
            )
        }
    }
}
