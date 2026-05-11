import SwiftUI

private enum CookleFloatingTabBarScrollLayout {
    static let bottomMargin: CGFloat = 96
}

extension View {
    func cookleFloatingTabBarScrollMargins() -> some View {
        contentMargins(
            .bottom,
            CookleFloatingTabBarScrollLayout.bottomMargin,
            for: .scrollContent
        )
    }
}
