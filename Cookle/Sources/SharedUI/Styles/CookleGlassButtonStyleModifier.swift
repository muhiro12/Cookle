import MHUI
import SwiftUI

struct CookleGlassButtonStyleModifier: ViewModifier {
    let isProminent: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isProminent {
            content.buttonStyle(.mhPrimary)
        } else {
            content.buttonStyle(.mhSecondary)
        }
    }
}
