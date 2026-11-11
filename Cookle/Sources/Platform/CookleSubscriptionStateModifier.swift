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
        let access: ICloudSyncOperations.SubscriptionAccess
        switch runtime.premiumStatus {
        case .unknown:
            access = .unknown
        case .inactive:
            access = .inactive
        case .active:
            access = .active
        }
        ICloudSyncOperations.updateSubscriptionAccess(
            access,
            store: runtime.preferenceStore
        )
    }
}
