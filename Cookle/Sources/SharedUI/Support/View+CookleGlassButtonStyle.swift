import MHUI
import SwiftUI

extension View {
    func cookleGlassButtonStyle(isProminent: Bool = false) -> some View {
        modifier(
            CookleGlassButtonStyleModifier(
                isProminent: isProminent
            )
        )
    }

    func cookleDestructiveButtonStyle() -> some View {
        buttonStyle(.mhDestructive)
    }
}
