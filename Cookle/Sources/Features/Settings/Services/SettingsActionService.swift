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

    func exportBackupPackage(
        modelContainer: ModelContainer
    ) async throws -> CookleDataArchivePackage {
        do {
            let context = modelContainer.mainContext
            let duplicateDayReport = try DiaryOperations.duplicateDayReport(
                context: context
            )
            guard duplicateDayReport.hasConflicts == false else {
                throw SettingsActionError.duplicateDiaryDays
            }
            return try await DataMaintenanceOperations.archivePackage(
                from: context
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as SettingsActionError {
            throw error
        } catch {
            throw SettingsActionError.backupCreationFailed
        }
    }

    nonisolated func validatedBackupArchive(
        from url: URL
    ) async throws -> CookleDataArchive {
        let calendar = Calendar.current
        let validationTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let archive = try CookleBackupFileReader.validatedArchive(
                from: url,
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
        let summary: CookleDataRestoreSummary
        do {
            summary = try DataMaintenanceOperations.restore(
                archive,
                context: modelContainer.mainContext
            )
        } catch {
            throw SettingsActionError.backupRestoreFailed
        }

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
    enum SettingsActionError: LocalizedError {
        case duplicateDiaryDays
        case backupCreationFailed
        case backupRestoreFailed

        var errorDescription: String? {
            switch self {
            case .duplicateDiaryDays:
                String(
                    localized: """
                    Open Diaries and merge duplicate diary entries before exporting a backup. \
                    No backup was created, and your data was not changed.
                    """
                )
            case .backupCreationFailed:
                String(
                    localized: "Cookle couldn’t create the backup. Your data was not changed."
                )
            case .backupRestoreFailed:
                String(
                    localized: "Cookle couldn’t restore the backup. Your current data was not changed."
                )
            }
        }
    }

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
