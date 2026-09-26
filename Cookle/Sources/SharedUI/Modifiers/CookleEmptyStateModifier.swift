import MHUI
import SwiftUI

/// Centers empty content in the available viewport while keeping tall content scrollable.
private struct CookleEmptyStateModifier: ViewModifier {
    @Environment(\.mhTheme)
    private var theme

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .mhEmptyStateLayout()
                    .frame(maxWidth: theme.layout.readableContentWidth)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .mhTextAppearance(.themed)
        .background {
            Rectangle()
                .mhForegroundStyle(.background)
                .ignoresSafeArea(.container)
        }
    }
}

extension View {
    func cookleEmptyState() -> some View {
        modifier(CookleEmptyStateModifier())
    }
}
