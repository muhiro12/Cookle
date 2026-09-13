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
