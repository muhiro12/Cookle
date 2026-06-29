import MHUI
import SwiftUI

struct CookleGlassSurfaceModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .mhSurface()
            .clipShape(shape)
    }
}
