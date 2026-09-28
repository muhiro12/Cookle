import SwiftUI

extension View {
    /// Wraps a long large title instead of truncating it to one line.
    func cookleWrappingLargeTitle(
        _ title: Text
    ) -> some View {
        modifier(
            CookleWrappingLargeTitleModifier(
                title: title
            )
        )
    }
}
