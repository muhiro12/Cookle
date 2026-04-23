import SwiftUI

extension View {
    func cookleIdleTimerDisabled(
        _ isDisabled: Bool = true
    ) -> some View {
        modifier(
            CookleIdleTimerDisabledModifier(
                isDisabled: isDisabled
            )
        )
    }
}
