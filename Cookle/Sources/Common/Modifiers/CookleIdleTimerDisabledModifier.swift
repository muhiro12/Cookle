import SwiftUI

struct CookleIdleTimerDisabledModifier: ViewModifier {
    let isDisabled: Bool

    @State private var hasActiveRequest = false

    func body(
        content: Content
    ) -> some View {
        content
            .onAppear {
                updateRequest(isActive: isDisabled)
            }
            .onChange(of: isDisabled) {
                updateRequest(isActive: isDisabled)
            }
            .onDisappear {
                updateRequest(isActive: false)
            }
    }

    private func updateRequest(
        isActive: Bool
    ) {
        guard isActive != hasActiveRequest else {
            return
        }

        if isActive {
            CookleIdleTimerDisableStore.acquire()
        } else {
            CookleIdleTimerDisableStore.release()
        }
        hasActiveRequest = isActive
    }
}
