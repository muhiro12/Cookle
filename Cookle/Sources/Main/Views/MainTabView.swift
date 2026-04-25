//
//  MainTabView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MainTabView: View {
    @Binding private var selection: MainTab
    @Binding private var diarySelection: Diary?
    @Binding private var diaryRecipeSelection: Recipe?
    @Binding private var recipeSelection: Recipe?
    @Binding private var photoSelection: Photo?
    @Binding private var searchSelection: Recipe?
    @Binding private var tagBrowser: MainTagBrowser?
    @Binding private var categorySelection: Category?
    @Binding private var categoryRecipeSelection: Recipe?
    @Binding private var ingredientSelection: Ingredient?
    @Binding private var ingredientRecipeSelection: Recipe?
    @Binding private var incomingSearchQuery: String?
    @Binding private var incomingSettingsSelection: SettingsContent?

    private var tabs: [MainTab] {
        MainTab.displayedTabs()
    }

    var body: some View {
        tabView
            .sheet(item: $tagBrowser) { browser in
                tagBrowserView(for: browser)
            }
    }

    @ViewBuilder var tabView: some View {
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

    init(
        selection: Binding<MainTab>,
        diarySelection: Binding<Diary?> = .constant(nil),
        diaryRecipeSelection: Binding<Recipe?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil),
        photoSelection: Binding<Photo?> = .constant(nil),
        searchSelection: Binding<Recipe?> = .constant(nil),
        tagBrowser: Binding<MainTagBrowser?> = .constant(nil),
        categorySelection: Binding<Category?> = .constant(nil),
        categoryRecipeSelection: Binding<Recipe?> = .constant(nil),
        ingredientSelection: Binding<Ingredient?> = .constant(nil),
        ingredientRecipeSelection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil),
        incomingSettingsSelection: Binding<SettingsContent?> = .constant(nil)
    ) {
        _selection = selection
        _diarySelection = diarySelection
        _diaryRecipeSelection = diaryRecipeSelection
        _recipeSelection = recipeSelection
        _photoSelection = photoSelection
        _searchSelection = searchSelection
        _tagBrowser = tagBrowser
        _categorySelection = categorySelection
        _categoryRecipeSelection = categoryRecipeSelection
        _ingredientSelection = ingredientSelection
        _ingredientRecipeSelection = ingredientRecipeSelection
        _incomingSearchQuery = incomingSearchQuery
        _incomingSettingsSelection = incomingSettingsSelection
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
        case .photo:
            PhotoNavigationView(selection: $photoSelection)
        }
    }

    @ViewBuilder
    func tagBrowserView(for browser: MainTagBrowser) -> some View {
        switch browser {
        case .category:
            TagNavigationView<Category>(
                selection: $categorySelection,
                recipeSelection: $categoryRecipeSelection
            )
        case .ingredient:
            TagNavigationView<Ingredient>(
                selection: $ingredientSelection,
                recipeSelection: $ingredientRecipeSelection
            )
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MainTabView(selection: .constant(.diary))
}
