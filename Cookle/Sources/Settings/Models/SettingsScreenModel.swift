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
    var isRestoreConfirmationPresented = false
    var isManageActionInProgress = false
    var isDailySuggestionTipEligible = false
    var isSubscriptionTipEligible = false
    var isShortcutsTipEligible = false
    var backupDocument: CookleDataArchiveDocument?
    var backupFilename = "Cookle-Backup"
    var pendingRestoreArchive: CookleDataArchive?
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

    func prepareBackupExport(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            backupDocument = .init(
                data: try settingsActionService.exportBackupData(
                    modelContainer: modelContainer
                )
            )
            backupFilename = Self.backupFilename()
            isBackupExporterPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareBackupRestore(
        from url: URL,
        settingsActionService: SettingsActionService
    ) {
        guard beginManageAction() else {
            return
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            pendingRestoreArchive = try settingsActionService.validatedBackupArchive(
                from: url
            )
            isRestoreConfirmationPresented = true
        } catch {
            pendingRestoreArchive = nil
            errorMessage = error.localizedDescription
        }
    }

    func restorePendingBackup(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async -> Bool {
        guard let pendingRestoreArchive,
              beginManageAction() else {
            return false
        }
        defer {
            isManageActionInProgress = false
        }

        do {
            let summary = try await settingsActionService.restoreBackup(
                pendingRestoreArchive,
                modelContainer: modelContainer
            )
            self.pendingRestoreArchive = nil
            statusMessage = Self.restoreMessage(
                summary
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func cancelPendingRestore() {
        pendingRestoreArchive = nil
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
        return "Cookle-Backup-\(formatter.string(from: now))"
    }

    static func restoreMessage(_ summary: CookleDataRestoreSummary) -> String {
        [
            "Restored \(summary.recipeCount) recipes",
            "\(summary.diaryCount) diaries",
            "\(summary.categoryCount) categories",
            "\(summary.ingredientCount) ingredients",
            "\(summary.photoCount) photos."
        ]
        .joined(separator: ", ")
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
