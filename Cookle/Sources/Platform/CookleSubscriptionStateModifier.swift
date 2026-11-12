import MHPlatform
import SwiftUI

struct CookleSubscriptionStateModifier: ViewModifier {
    let runtime: MHAppRuntime

    func body(content: Content) -> some View {
        content
            .onChange(of: runtime.premiumStatus, initial: true) {
                synchronizeSubscriptionState()
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
