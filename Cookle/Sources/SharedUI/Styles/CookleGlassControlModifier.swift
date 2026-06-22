import SwiftUI

struct CookleGlassControlModifier<S: Shape>: ViewModifier {
    let shape: S
    let isInteractive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.interactive(isInteractive),
                in: shape
            )
        } else {
            content.background(
                .thinMaterial,
                in: shape
            )
        }
    }
}
