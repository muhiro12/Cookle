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
    var isDailySuggestionTipEligible = false
    var isSubscriptionTipEligible = false
    var isShortcutsTipEligible = false
    var errorMessage: String?

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

    func deleteAllData(
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) async -> Bool {
        do {
            errorMessage = nil
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
