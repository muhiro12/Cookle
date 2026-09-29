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
    var isDataExporterPresented = false
    var isDataImporterPresented = false
    var isImportPresented = false
    var isManageActionInProgress = false
    var isDailySuggestionTipEligible = false
    var isSubscriptionTipEligible = false
    var isShortcutsTipEligible = false
    var exportDocument: CookleDataArchiveDocument?
    var exportFilename = "Cookle-Export.cookle"
    var pendingImport: PendingDataImport?
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

    func prepareDataExport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        exportDocument = nil
        do {
            exportDocument = .init(
                archivePackage: try await settingsActionService.exportDataPackage(
                    modelContainer: modelContainer
                )
            )
            exportFilename = Self.exportFilename()
            isDataExporterPresented = true
        } catch is CancellationError {
            // Leaving Settings cancels export preparation without showing an error.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Validates the chosen file and builds its import review without changing data.
    func prepareDataImport(
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
            let archive = try await settingsActionService.validatedImportArchive(
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
            isImportPresented = true
        } catch is CancellationError {
            pendingImport = nil
        } catch {
            pendingImport = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Merges the pending file, adding new items and updating every matching
    /// item with the file's content.
    func mergePendingImport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard let pendingImport else {
            return
        }

        await applyPendingImport(
            selections: .updatingMatchingData(for: pendingImport.review),
            modelContainer: modelContainer,
            settingsActionService: settingsActionService
        )
    }

    /// Merges the pending file with the choice made for each differing item.
    func importPendingSelections(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard let pendingImport,
              pendingImport.isReadyToImport else {
            return
        }

        await applyPendingImport(
            selections: pendingImport.selections,
            modelContainer: modelContainer,
            settingsActionService: settingsActionService
        )
    }

    /// Replaces all current data with the pending complete-library file.
    func replaceWithPendingImport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard let pendingImport,
              pendingImport.canReplace,
              beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        importErrorMessage = nil
        do {
            let summary = try await settingsActionService.replaceAllData(
                with: pendingImport.archive,
                modelContainer: modelContainer
            )
            finishImport(message: Self.replacementMessage(summary))
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
        isImportPresented = false
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
    static func exportFilename(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .init(identifier: .gregorian)
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "Cookle-Export-\(formatter.string(from: now)).cookle"
    }

    static func mergeMessage(_ summary: CookleDataImportSummary) -> String {
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
            String(localized: "The file was merged into your data."),
            recipes,
            diaries,
            photos
        ]
        .joined(separator: "\n")
    }

    static func replacementMessage(_ summary: CookleDataReplacementSummary) -> String {
        [
            String(localized: "Your data was replaced with the file's content."),
            String(
                localized: """
                Recipes: \(summary.recipeCount). Diaries: \(summary.diaryCount). \
                Photos: \(summary.photoCount).
                """
            )
        ]
        .joined(separator: "\n")
    }

    /// Applies `selections` to the pending file.
    ///
    /// When current data changed after the review, the review is rebuilt,
    /// per-item choices for changed conflicts are cleared, and nothing is
    /// imported until the person confirms again. Other failures keep the
    /// pending file for a retry.
    func applyPendingImport(
        selections: CookleDataImportSelections,
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async {
        guard var pendingImport,
              beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        importErrorMessage = nil
        do {
            let summary = try await settingsActionService.importData(
                pendingImport.archive,
                review: pendingImport.review,
                selections: selections,
                modelContainer: modelContainer
            )
            finishImport(message: Self.mergeMessage(summary))
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

    func finishImport(message: String) {
        pendingImport = nil
        isImportPresented = false
        statusMessage = message
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
