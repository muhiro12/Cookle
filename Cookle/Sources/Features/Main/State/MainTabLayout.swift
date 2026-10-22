import SwiftUI

/// The two tab arrangements being compared, with and without AI.
enum MainTabLayout: CaseIterable {
    case aiProminent
    case aiIntegrated
    case searchProminent
    case searchIntegrated

    var includesAI: Bool {
        switch self {
        case .aiProminent, .aiIntegrated:
            true
        case .searchProminent, .searchIntegrated:
            false
        }
    }

    var tabs: [MainTab] {
        MainTab.displayedTabs(includesAI: includesAI)
    }

    @available(iOS 18, *)
    func role(for tab: MainTab) -> TabRole? {
        if self == .searchProminent, tab == .search {
            return .search
        }
        #if compiler(>=6.4)
        if #available(iOS 27, *), self == .aiProminent, tab == .aiRecipe {
            return .prominent
        }
        #endif
        return nil
    }
}
