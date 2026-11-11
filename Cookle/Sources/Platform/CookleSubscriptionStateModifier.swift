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
        let isActive: Bool?
        switch runtime.premiumStatus {
        case .unknown:
            isActive = nil
        case .inactive:
            isActive = false
        case .active:
            isActive = true
        }
        ICloudSyncOperations.updateSubscriptionAccess(
            isActive: isActive,
            store: runtime.preferenceStore
        )
    }
}
