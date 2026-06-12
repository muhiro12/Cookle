import SwiftUI

extension View {
    func cookleGlassButtonStyle(isProminent: Bool = false) -> some View {
        modifier(
            CookleGlassButtonStyleModifier(
                isProminent: isProminent
            )
        )
    }
}
