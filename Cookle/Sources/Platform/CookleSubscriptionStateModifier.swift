import MHPlatform
import StoreKit
import SwiftUI

struct CookleSubscriptionStateModifier: ViewModifier {
    let runtime: MHAppRuntime
    let entitlementRefresh: CookleSubscriptionEntitlementRefresh

    func body(content: Content) -> some View {
        content
            .onChange(of: runtime.premiumStatus, initial: true) {
                synchronizeSubscriptionState()
            }
            .subscriptionStatusTask(for: CookleMonetizationConfiguration.subscriptionGroupID) { state in
                guard case .success = state else {
                    return
                }

                await entitlementRefresh.refresh()
            }
    }
}

private extension CookleSubscriptionStateModifier {
    func synchronizeSubscriptionState() {
        switch runtime.premiumStatus {
        case .unknown:
            return
        case .inactive:
            runtime.preferenceStore.set(
                false,
                for: \.isSubscribeOn
            )
            runtime.preferenceStore.set(
                false,
                for: \.isICloudOn
            )
        case .active:
            runtime.preferenceStore.set(
                true,
                for: \.isSubscribeOn
            )
        }
    }
}
