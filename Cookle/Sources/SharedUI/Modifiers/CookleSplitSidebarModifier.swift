import MHUI
import SwiftUI

private struct CookleSplitSidebarModifier: ViewModifier {
    let isExpanded: Bool

    func body(content: Content) -> some View {
        content.environment(
            \.cookleSplitSidebarBackground,
            isExpanded ? .native : .themed
        )
    }
}

extension EnvironmentValues {
    @Entry var cookleSplitSidebarBackground: MHContainerBackground = .themed
}

extension View {
    /// Leaves expanded split sidebars on the platform plane while compact
    /// screens retain their themed canvas. Content lists keep MHUI defaults.
    func cookleSplitSidebar(isExpanded: Bool) -> some View {
        modifier(CookleSplitSidebarModifier(isExpanded: isExpanded))
    }
}
