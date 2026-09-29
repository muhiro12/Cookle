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

    func exportDataPackage(
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
            throw SettingsActionError.exportFailed
        }
    }

    nonisolated func validatedImportArchive(
        from url: URL
    ) async throws -> CookleDataArchive {
        let calendar = Calendar.current
        let validationTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let archive = try CookleDataFileReader.validatedArchive(
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

    /// Builds the import review for a validated file without changing data.
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
            throw SettingsActionError.importFailed
        }
    }

    /// Merges a reviewed file using a choice for every conflict.
    ///
    /// A changed review is rethrown unchanged so the caller can ask again;
    /// every other failure leaves current data as it was.
    func importData(
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
            throw SettingsActionError.importFailed
        }

        await reloadAfterImport()
        return summary
    }

    /// Replaces all current data with a complete-library file.
    ///
    /// Every failure leaves current data as it was.
    func replaceAllData(
        with archive: CookleDataArchive,
        modelContainer: ModelContainer
    ) async throws -> CookleDataReplacementSummary {
        try CookleMutationWorkflow.requireCleanContext(modelContainer.mainContext)
        let summary: CookleDataReplacementSummary
        do {
            summary = try DataMaintenanceOperations.replaceAllData(
                with: archive,
                context: modelContainer.mainContext
            )
        } catch {
            throw SettingsActionError.importFailed
        }

        await reloadAfterImport()
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
        case exportFailed
        case importFailed

        var errorDescription: String? {
            switch self {
            case .duplicateDiaryDays:
                String(
                    localized: """
                    Open Diaries and merge duplicate diary entries before exporting your data. \
                    No file was created, and your data was not changed.
                    """
                )
            case .exportFailed:
                String(
                    localized: "Cookle couldn’t export your data. Your data was not changed."
                )
            case .duplicateDiaryDaysBeforeImport:
                String(
                    localized: """
                    Some days in this file already have more than one diary on this device. Open Diaries \
                    and merge duplicate diary entries, then import again. Your data was not changed.
                    """
                )
            case .importFailed:
                String(
                    localized: "Cookle couldn’t import the file. Your current data was not changed."
                )
            }
        }
    }

    func reloadAfterImport() async {
        CookleWidgetReloader.reloadTodayDiaryWidget()
        CookleWidgetReloader.reloadRecipeWidgets()
        await notificationService.synchronizeScheduledSuggestions()
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
