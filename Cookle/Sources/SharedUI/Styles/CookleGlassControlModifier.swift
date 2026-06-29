import MHUI
import SwiftUI

struct CookleGlassControlModifier<S: Shape>: ViewModifier {
    let shape: S
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if isInteractive {
            content
                .mhSurface()
                .clipShape(shape)
        } else {
            content
                .mhSurface(role: .muted)
                .clipShape(shape)
        }
    }
}
