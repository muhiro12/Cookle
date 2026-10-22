import SwiftUI

/// Native navigation and input arrangements for the temporary comparison.
enum MainTabLayout: CaseIterable {
    case aiProminent
    case aiIntegrated
    case searchProminent
    case searchIntegrated
    case aiSearchTab
    case aiRequestForm
    case recipeModal
    case aiSearchToolbar
    case aiTabAccessory
    case aiFixedPreferenceEntry

    var includesAI: Bool {
        switch self {
        case .aiProminent, .aiIntegrated, .aiSearchTab, .aiRequestForm, .aiSearchToolbar,
             .aiTabAccessory, .aiFixedPreferenceEntry:
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
        case .aiSearchTab:
            .searchTab
        case .aiRequestForm:
            .form
        case .aiSearchToolbar:
            .searchToolbar
        case .aiTabAccessory, .aiFixedPreferenceEntry:
            .requestStack
        case .aiProminent, .aiIntegrated, .searchProminent, .searchIntegrated, .recipeModal:
            .editor
        }
    }

    var activatesSearchOnSelection: Bool {
        self == .searchProminent || self == .recipeModal || self == .aiSearchTab
    }

    @available(iOS 18, *)
    func role(for tab: MainTab) -> TabRole? {
        if self == .searchProminent || self == .recipeModal, tab == .search {
            return .search
        }
        if self == .aiSearchTab, tab == .aiRecipe {
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
