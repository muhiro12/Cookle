#if DEBUG
import SwiftUI

enum AIInputComparisonLayout: CaseIterable, Identifiable {
    case tabs
    case sidebar
    case sidebarToolbar

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .tabs:
            "Tabs + Bottom Input"
        case .sidebar:
            "Sidebar + Bottom Input"
        case .sidebarToolbar:
            "Sidebar + Toolbar Input"
        }
    }
}
#endif
