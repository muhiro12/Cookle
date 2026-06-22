import SwiftUI

struct CookleGlassSurfaceModifier<S: Shape>: ViewModifier {
    let shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular,
                in: shape
            )
        } else {
            content.background(
                .background,
                in: shape
            )
        }
    }
}
