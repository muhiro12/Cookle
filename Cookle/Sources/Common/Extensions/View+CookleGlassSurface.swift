import SwiftUI

extension View {
    func cookleGlassSurface<S: Shape>(
        in shape: S
    ) -> some View {
        modifier(
            CookleGlassSurfaceModifier(
                shape: shape
            )
        )
    }
}
