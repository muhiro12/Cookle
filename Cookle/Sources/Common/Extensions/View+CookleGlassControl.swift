import SwiftUI

extension View {
    func cookleGlassControl<S: Shape>(
        in shape: S,
        isInteractive: Bool = true
    ) -> some View {
        modifier(
            CookleGlassControlModifier(
                shape: shape,
                isInteractive: isInteractive
            )
        )
    }
}
