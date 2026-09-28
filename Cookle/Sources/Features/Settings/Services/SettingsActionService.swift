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

    /// Builds the merge review for a validated backup without changing data.
    func importReview(
        for archive: CookleDataArchive,
        modelContainer: ModelContainer
    ) throws -> CookleDataImportReview {
        do {
            return try DataMaintenanceOperations.importReview(
                for: archive,
                context: modelContainer.mainContext
            )
        } catch CookleDataImportError.duplicateCurrentDiaryDays {
            throw SettingsActionError.duplicateDiaryDaysBeforeImport
        } catch {
            throw SettingsActionError.backupImportFailed
        }
    }

    /// Merges a reviewed backup using a choice for every conflict.
    ///
    /// A changed review is rethrown unchanged so the caller can ask again;
    /// every other failure leaves current data as it was.
    func importBackup(
        _ archive: CookleDataArchive,
        review: CookleDataImportReview,
        selections: CookleDataImportSelections,
        modelContainer: ModelContainer
    ) async throws -> CookleDataImportSummary {
        try CookleMutationWorkflow.requireCleanContext(modelContainer.mainContext)
        let summary: CookleDataImportSummary
        do {
            summary = try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: selections,
                context: modelContainer.mainContext
            )
        } catch let error as CookleDataImportError {
            if case .duplicateCurrentDiaryDays = error {
                throw SettingsActionError.duplicateDiaryDaysBeforeImport
            }
            throw error
        } catch {
            throw SettingsActionError.backupImportFailed
        }

        CookleWidgetReloader.reloadTodayDiaryWidget()
        CookleWidgetReloader.reloadRecipeWidgets()
        await notificationService.synchronizeScheduledSuggestions()
        return summary
    }

    func deleteAllData(modelContainer: ModelContainer) async throws {
        let context = modelContainer.mainContext
        try CookleMutationWorkflow.requireCleanContext(context)
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
        case duplicateDiaryDaysBeforeImport
        case backupCreationFailed
        case backupImportFailed

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
            case .duplicateDiaryDaysBeforeImport:
                String(
                    localized: """
                    Some days in this backup already have more than one diary. Open Diaries and merge \
                    duplicate diary entries, then import again. Your data was not changed.
                    """
                )
            case .backupImportFailed:
                String(
                    localized: "Cookle couldn’t import the backup. Your current data was not changed."
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
