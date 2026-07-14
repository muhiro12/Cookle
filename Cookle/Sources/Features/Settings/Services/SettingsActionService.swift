import Foundation
import Observation
@preconcurrency import SwiftData

@MainActor
@Observable
final class SettingsActionService {
    nonisolated private enum BackupFileRead {
        static let chunkKibibytes = 64
        static let bytesPerKibibyte = 1_024
        static let chunkByteCount = chunkKibibytes * bytesPerKibibyte
    }

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
        let context = modelContainer.mainContext
        let duplicateDayReport = try DiaryOperations.duplicateDayReport(
            context: context
        )
        guard duplicateDayReport.hasConflicts == false else {
            throw SettingsActionError.duplicateDiaryDays
        }
        return try DataMaintenanceOperations.encodedArchive(
            from: context
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

            let data = try Self.readBackupData(
                from: url,
                maximumByteCount: DataMaintenanceOperations.maximumEncodedArchiveByteCount
            )
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
    enum SettingsActionError: LocalizedError {
        case duplicateDiaryDays

        var errorDescription: String? {
            String(
                localized: """
                Open Diaries and merge duplicate diary entries before exporting a backup. \
                No backup was created, and your data was not changed.
                """
            )
        }
    }

    nonisolated static func readBackupData(
        from url: URL,
        maximumByteCount: Int
    ) throws -> Data {
        let fileHandle = try FileHandle(
            forReadingFrom: url
        )
        defer {
            try? fileHandle.close()
        }

        var data = Data()

        while data.count <= maximumByteCount {
            try Task.checkCancellation()
            let remainingByteCount = maximumByteCount - data.count
            let readByteCount: Int
            if remainingByteCount >= BackupFileRead.chunkByteCount {
                readByteCount = BackupFileRead.chunkByteCount
            } else {
                readByteCount = remainingByteCount + 1
            }
            let dataChunk = try fileHandle.read(
                upToCount: readByteCount
            )
            guard let dataChunk,
                  dataChunk.isEmpty == false else {
                break
            }
            data.append(dataChunk)
        }
        return data
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
