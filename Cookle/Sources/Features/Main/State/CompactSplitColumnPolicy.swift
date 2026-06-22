import SwiftUI

enum CompactSplitColumnPolicy {
    static func twoColumn(
        hasDetailSelection: Bool
    ) -> NavigationSplitViewColumn {
        if hasDetailSelection {
            return .detail
        }

        return .sidebar
    }

    static func threeColumn(
        hasContentSelection: Bool,
        hasDetailSelection: Bool
    ) -> NavigationSplitViewColumn {
        if hasDetailSelection {
            return .detail
        }

        if hasContentSelection {
            return .content
        }

        return .sidebar
    }
}
