import SwiftUI

extension View {
    func cookleGlassButtonStyle(isProminent: Bool = false) -> some View {
        frame(
            minWidth: CookleAccessibilityLayout.minimumHitTargetSize,
            minHeight: CookleAccessibilityLayout.minimumHitTargetSize
        )
        .controlSize(.large)
        .modifier(
            CookleGlassButtonStyleModifier(
                isProminent: isProminent
            )
        )
    }
}
