import SwiftUI
import Testing
import TipKit

@testable import Cookle

struct SettingsScreenModelTests {
    private struct DailySuggestionTipStub: Tip {
        var title: Text {
            Text("Daily")
        }
    }

    private struct SubscriptionTipStub: Tip {
        var title: Text {
            Text("Subscription")
        }
    }

    private struct ShortcutsTipStub: Tip {
        var title: Text {
            Text("Shortcuts")
        }
    }

    @Test
    @MainActor
    func currentTip_prefersDailySuggestionTip() {
        let model = SettingsScreenModel()
        let dailyTip = DailySuggestionTipStub()
        let subscriptionTip = SubscriptionTipStub()
        let shortcutsTip = ShortcutsTipStub()

        let resolvedTip = model.currentTip(
            for: dailyTip,
            context: .init(
                dailySuggestionTipID: dailyTip.id,
                subscriptionTipID: subscriptionTip.id,
                shortcutsTipID: shortcutsTip.id,
                shouldShowDailySuggestionTip: true,
                shouldShowSubscriptionTip: true,
                shouldShowShortcutsTip: true
            )
        )

        #expect(resolvedTip?.id == dailyTip.id)
    }

    @Test
    @MainActor
    func currentTip_fallsBackToShortcutsWhenHigherPriorityTipsAreHidden() {
        let model = SettingsScreenModel()
        let dailyTip = DailySuggestionTipStub()
        let subscriptionTip = SubscriptionTipStub()
        let shortcutsTip = ShortcutsTipStub()

        let resolvedTip = model.currentTip(
            for: shortcutsTip,
            context: .init(
                dailySuggestionTipID: dailyTip.id,
                subscriptionTipID: subscriptionTip.id,
                shortcutsTipID: shortcutsTip.id,
                shouldShowDailySuggestionTip: false,
                shouldShowSubscriptionTip: false,
                shouldShowShortcutsTip: true
            )
        )

        #expect(resolvedTip?.id == shortcutsTip.id)
    }
}
