import SwiftUI

/// Native navigation and input arrangements for the temporary comparison.
enum MainTabLayout: CaseIterable {
    case aiProminent
    case aiIntegrated
    case searchProminent
    case searchIntegrated
    case aiBottomComposer
    case aiRequestForm
    case recipeModal

    var includesAI: Bool {
        switch self {
        case .aiProminent, .aiIntegrated, .aiBottomComposer, .aiRequestForm:
            true
        case .searchProminent, .searchIntegrated, .recipeModal:
            false
        }
    }

    var tabs: [MainTab] {
        MainTab.displayedTabs(includesAI: includesAI)
    }

    var generationInputStyle: RecipeGenerationInputStyle {
        switch self {
        case .aiBottomComposer:
            .bottomComposer
        case .aiRequestForm:
            .form
        case .aiProminent, .aiIntegrated, .searchProminent, .searchIntegrated, .recipeModal:
            .editor
        }
    }

    @available(iOS 18, *)
    func role(for tab: MainTab) -> TabRole? {
        if self == .searchProminent || self == .recipeModal, tab == .search {
            return .search
        }
        #if compiler(>=6.4)
        if #available(iOS 27, *),
           self != .aiIntegrated,
           includesAI,
           tab == .aiRecipe {
            return .prominent
        }
        #endif
        return nil
    }
}
