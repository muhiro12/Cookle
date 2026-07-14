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
        await notificationService.refreshAuthorizationStatus()
    }

    func applyNotificationSettings() async {
        normalizeNotificationDefaultsIfNeeded()
        await notificationService.applySuggestionSettings()
    }

    func exportBackupData(modelContainer: ModelContainer) throws -> Data {
        try DataMaintenanceOperations.encodedArchive(
            from: modelContainer.mainContext
        )
    }

    nonisolated func validatedBackupArchive(
        from url: URL
    ) async throws -> CookleDataArchive {
        let calendar = Calendar.current
        let validationTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
            defer {
                if didAccessSecurityScopedResource {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            try Task.checkCancellation()
            let archive = try DataMaintenanceOperations.validatedArchive(
                from: data,
                calendar: calendar
            )
            try Task.checkCancellation()
            return archive
        }
        return try await withTaskCancellationHandler {
            try await validationTask.value
        } onCancel: {
            validationTask.cancel()
        }
    }

    func restoreBackup(
        _ archive: CookleDataArchive,
        modelContainer: ModelContainer
    ) async throws -> CookleDataRestoreSummary {
        let summary = try DataMaintenanceOperations.restore(
            archive,
            context: modelContainer.mainContext
        )

        CookleWidgetReloader.reloadTodayDiaryWidget()
        CookleWidgetReloader.reloadRecipeWidgets()
        await notificationService.synchronizeScheduledSuggestions()
        return summary
    }

    func deleteAllData(modelContainer: ModelContainer) async throws {
        let context = modelContainer.mainContext
        let mutationOutcome: MutationOutcome<Void>
        do {
            mutationOutcome = try DataMaintenanceOperations.deleteAllWithOutcome(
                context: context
            )
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

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
