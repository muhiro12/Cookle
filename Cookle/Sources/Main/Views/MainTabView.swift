//
//  MainTabView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @AppStorage(.isDebugOn) private var isDebugOn

    @Binding private var selection: MainTab
    @Binding private var diarySelection: Diary?
    @Binding private var diaryRecipeSelection: Recipe?
    @Binding private var recipeSelection: Recipe?
    @Binding private var searchSelection: Recipe?
    @Binding private var incomingSearchQuery: String?
    @Binding private var incomingSettingsSelection: SettingsContent?

    init(
        selection: Binding<MainTab>,
        diarySelection: Binding<Diary?> = .constant(nil),
        diaryRecipeSelection: Binding<Recipe?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil),
        searchSelection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil),
        incomingSettingsSelection: Binding<SettingsContent?> = .constant(nil)
    ) {
        _selection = selection
        _diarySelection = diarySelection
        _diaryRecipeSelection = diaryRecipeSelection
        _recipeSelection = recipeSelection
        _searchSelection = searchSelection
        _incomingSearchQuery = incomingSearchQuery
        _incomingSettingsSelection = incomingSettingsSelection
    }

    private var tabs: [MainTab] {
        MainTab.allCases.filter {
            switch $0 {
            case .diary, .recipe, .photo, .search:
                true
            case .ingredient, .category, .settings:
                horizontalSizeClass == .regular
            case .menu:
                horizontalSizeClass == .compact || !isDebugOn
            case .debug:
                horizontalSizeClass == .regular && isDebugOn
            }
        }
    }

    var body: some View {
        if #available(iOS 18, *) {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    Tab(value: tab, role: tab == .search ? .search : nil) {
                        rootView(for: tab)
                    } label: {
                        tab.label
                    }
                }
            }
        } else {
            TabView(selection: $selection) {
                ForEach(tabs) { tab in
                    rootView(for: tab)
                        .tag(tab)
                        .tabItem {
                            tab.label
                        }
                }
            }
        }
    }
}

private extension MainTabView {
    @ViewBuilder
    func rootView(for tab: MainTab) -> some View {
        switch tab {
        case .diary:
            DiaryNavigationView(
                selection: $diarySelection,
                recipeSelection: $diaryRecipeSelection
            )
        case .recipe:
            RecipeNavigationView(selection: $recipeSelection)
        case .search:
            SearchNavigationView(
                selection: $searchSelection,
                incomingSearchQuery: $incomingSearchQuery
            )
        case .settings:
            SettingsNavigationView(
                incomingSelection: $incomingSettingsSelection
            )
        case .photo,
             .ingredient,
             .category,
             .menu,
             .debug:
            tab.rootView
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MainTabView(selection: .constant(.diary))
}
