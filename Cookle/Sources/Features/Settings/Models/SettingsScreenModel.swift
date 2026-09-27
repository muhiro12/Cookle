import Foundation
import Observation
import SwiftData
import TipKit

@MainActor
@Observable
final class SettingsScreenModel {
    struct TipDisplayContext {
        let dailySuggestionTipID: String
        let subscriptionTipID: String
        let shortcutsTipID: String
        let shouldShowDailySuggestionTip: Bool
        let shouldShowSubscriptionTip: Bool
        let shouldShowShortcutsTip: Bool
    }

    var isDeleteAllConfirmationPresented = false
    var isBackupExporterPresented = false
    var isBackupImporterPresented = false
    var isImportReviewPresented = false
    var isManageActionInProgress = false
    var isDailySuggestionTipEligible = false
    var isSubscriptionTipEligible = false
    var isShortcutsTipEligible = false
    var backupDocument: CookleDataArchiveDocument?
    var backupFilename = "Cookle-Backup.cooklebackup"
    var pendingImport: PendingBackupImport?
    var importErrorMessage: String?
    var errorMessage: String?
    var statusMessage: String?

    func prepareNotificationSettings(
        settingsActionService: SettingsActionService
    ) async {
        await settingsActionService.prepareNotificationSettings()
    }

    func applyNotificationSettings(
        settingsActionService: SettingsActionService
    ) async {
        await settingsActionService.applyNotificationSettings()
    }

    func sendTestSuggestionNotification(
        notificationService: NotificationService
    ) async {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            try await notificationService.sendTestSuggestionNotification()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareBackupExport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        backupDocument = nil
        do {
            backupDocument = .init(
                archivePackage: try await settingsActionService.exportBackupPackage(
                    modelContainer: modelContainer
                )
            )
            backupFilename = Self.backupFilename()
            isBackupExporterPresented = true
        } catch is CancellationError {
            // Leaving Settings cancels backup preparation without showing an error.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Validates the chosen file and builds its merge review without changing data.
    func prepareBackupImport(
        from url: URL,
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            let archive = try await settingsActionService.validatedBackupArchive(
                from: url
            )
            pendingImport = .init(
                archive: archive,
                review: try settingsActionService.importReview(
                    for: archive,
                    modelContainer: modelContainer
                )
            )
            importErrorMessage = nil
            isImportReviewPresented = true
        } catch is CancellationError {
            pendingImport = nil
        } catch {
            pendingImport = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Merges the pending backup with the chosen conflict resolutions.
    ///
    /// When current data changed after the review, the review is rebuilt,
    /// choices for changed conflicts are cleared, and nothing is imported until
    /// the user confirms again. Other failures keep the review for a retry.
    func importPendingBackup(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard var pendingImport,
              pendingImport.isReadyToImport,
              beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        importErrorMessage = nil
        do {
            let summary = try await settingsActionService.importBackup(
                pendingImport.archive,
                review: pendingImport.review,
                selections: pendingImport.selections,
                modelContainer: modelContainer
            )
            self.pendingImport = nil
            isImportReviewPresented = false
            statusMessage = Self.importMessage(summary)
        } catch CookleDataImportError.reviewChanged(let currentReview) {
            pendingImport.selections = pendingImport.selections.retainingUnchangedChoices(
                from: pendingImport.review,
                in: currentReview
            )
            pendingImport.review = currentReview
            pendingImport.presentationID = UUID()
            pendingImport.isReviewRefreshed = true
            self.pendingImport = pendingImport
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    func cancelPendingImport() {
        guard isManageActionInProgress == false else {
            return
        }

        pendingImport = nil
        importErrorMessage = nil
        isImportReviewPresented = false
    }

    func deleteAllData(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async -> Bool {
        guard beginManageAction() else {
            return false
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            try await settingsActionService.deleteAllData(
                modelContainer: modelContainer
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func refreshTipEligibility<T: Tip, U: Tip, V: Tip>(
        dailySuggestionTip: T,
        subscriptionTip: U,
        shortcutsTip: V
    ) {
        isDailySuggestionTipEligible = dailySuggestionTip.shouldDisplay
        isSubscriptionTipEligible = subscriptionTip.shouldDisplay
        isShortcutsTipEligible = shortcutsTip.shouldDisplay
    }

    func currentTip<T: Tip>(
        for tip: T,
        context: TipDisplayContext
    ) -> (any Tip)? {
        if context.shouldShowDailySuggestionTip {
            return context.dailySuggestionTipID == tip.id ? tip : nil
        }
        if context.shouldShowSubscriptionTip {
            return context.subscriptionTipID == tip.id ? tip : nil
        }
        if context.shouldShowShortcutsTip {
            return context.shortcutsTipID == tip.id ? tip : nil
        }
        return nil
    }

    func observeDailySuggestionTipEligibility<T: Tip>(
        _ tip: T
    ) async {
        await MainActor.run {
            isDailySuggestionTipEligible = tip.shouldDisplay
        }

        for await shouldDisplay in tip.shouldDisplayUpdates {
            await MainActor.run {
                isDailySuggestionTipEligible = shouldDisplay
            }
        }
    }

    func observeSubscriptionTipEligibility<T: Tip>(
        _ tip: T
    ) async {
        await MainActor.run {
            isSubscriptionTipEligible = tip.shouldDisplay
        }

        for await shouldDisplay in tip.shouldDisplayUpdates {
            await MainActor.run {
                isSubscriptionTipEligible = shouldDisplay
            }
        }
    }

    func observeShortcutsTipEligibility<T: Tip>(
        _ tip: T
    ) async {
        await MainActor.run {
            isShortcutsTipEligible = tip.shouldDisplay
        }

        for await shouldDisplay in tip.shouldDisplayUpdates {
            await MainActor.run {
                isShortcutsTipEligible = shouldDisplay
            }
        }
    }
}

private extension SettingsScreenModel {
    static func backupFilename(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .init(identifier: .gregorian)
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "Cookle-Backup-\(formatter.string(from: now)).cooklebackup"
    }

    static func importMessage(_ summary: CookleDataImportSummary) -> String {
        // Whole sentences rather than joined fragments: word order and the
        // position of each count differ per language.
        let recipes = String(
            localized: """
            Recipes: \(summary.addedRecipeCount) added, \(summary.updatedRecipeCount) replaced, \
            \(summary.keptRecipeCount) kept, \(summary.unchangedRecipeCount) unchanged.
            """
        )
        let diaries = String(
            localized: """
            Diaries: \(summary.addedDiaryCount) added, \(summary.updatedDiaryCount) replaced, \
            \(summary.combinedDiaryCount) combined, \(summary.keptDiaryCount) kept, \
            \(summary.unchangedDiaryCount) unchanged.
            """
        )
        let photos = String(localized: "Photos added: \(summary.addedPhotoCount).")
        return [
            String(localized: "The backup was merged into your data."),
            recipes,
            diaries,
            photos
        ]
        .joined(separator: "\n")
    }

    func beginManageAction() -> Bool {
        guard isManageActionInProgress == false else {
            return false
        }

        isManageActionInProgress = true
        errorMessage = nil
        statusMessage = nil
        return true
    }
}
