import MHUI
import SwiftUI

/// Lets a long screen title wrap while the navigation bar shows its large title.
///
/// The native large title is limited to one line. This replaces only the
/// expanded presentation; the collapsed inline title, back button, and window
/// title still come from the screen's navigation title.
struct CookleWrappingLargeTitleModifier: ViewModifier {
    private enum Layout {
        /// Restores the space above the native large title, whose title area
        /// is taller than one line of text at the default text size.
        static let nativeTopInset: CGFloat = 11.5
    }

    let title: Text

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .largeTitle) {
                    title
                        .mhTextStyle(.screenTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Layout.nativeTopInset)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        } else {
            content
        }
    }
}
