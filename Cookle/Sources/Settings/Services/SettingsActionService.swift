import Foundation
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

    func exportBackupData(modelContainer: ModelContainer) throws -> Data {
        try CookleDataArchiveService.encodedArchive(
            from: modelContainer.mainContext
        )
    }

    func validatedBackupArchive(from url: URL) throws -> CookleDataArchive {
        let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try CookleDataArchiveService.validatedArchive(
            from: Data(contentsOf: url)
        )
    }

    func restoreBackup(
        _ archive: CookleDataArchive,
        modelContainer: ModelContainer
    ) async throws -> CookleDataRestoreSummary {
        let summary = try CookleDataArchiveService.restore(
            archive,
            context: modelContainer.mainContext
        )

        CookleWidgetReloader.reloadTodayDiaryWidget()
        CookleWidgetReloader.reloadRecipeWidgets()
        await notificationService.synchronizeScheduledSuggestions()
        return summary
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
