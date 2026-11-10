import MHUI
import SwiftUI

/// Lets a long screen title wrap while the navigation bar shows its large title.
///
/// The native large title is limited to one line. This replaces only the
/// expanded presentation; the collapsed inline title, back button, and window
/// title still come from the screen's navigation title.
/// Vertical bars keep the native title so it can avoid sidebar controls.
struct CookleWrappingLargeTitleModifier: ViewModifier {
    private enum Layout {
        /// Restores the space above the native large title, whose title area
        /// is taller than one line of text at the default text size.
        static let nativeTopInset: CGFloat = 11.5
    }

    let title: Text

    private var wrappingTitle: some View {
        title
            .mhTextStyle(.screenTitle)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Layout.nativeTopInset)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 27.1, *) {
            content.modifier(
                CookleAdaptiveLargeTitleModifier(title: wrappingTitle)
            )
        } else if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .largeTitle) {
                    wrappingTitle
                }
            }
        } else {
            content
        }
    }
}
