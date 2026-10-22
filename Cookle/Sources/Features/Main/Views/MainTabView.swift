//
//  MainTabView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(MainNavigationModel.self)
    private var navigationModel

    @State private var isAIAvailable = RecipeDraftSource.generation.isAvailable
    @State private var aiRecipeRequest = ""
    @State private var aiRecipeRequestLine = ""
    @State private var isAIRecipeLoading = false

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

    private var layout: MainTabLayout {
        #if DEBUG
        if let preview = navigationModel.tabLayoutPreview {
            return preview
        }
        #endif
        return isAIAvailable ? .aiProminent : .searchProminent
    }

    private var tabs: [MainTab] {
        layout.tabs
    }

    private var generationInputStyle: RecipeGenerationInputStyle {
        if layout == .aiTabAccessory, horizontalSizeClass != .compact {
            return .form
        }
        return layout.generationInputStyle
    }

    /// Availability can change while AI is selected. Never render a missing selection.
    private var visibleSelection: Binding<MainTab> {
        .init(
            get: {
                tabs.contains(selection) ? selection : .diary
            },
            set: { tab in
                selection = tab
            }
        )
    }

    var body: some View {
        comparisonTabView
            .sheet(item: $tagBrowser) { browser in
                tagBrowserView(for: browser)
            }
            .onChange(of: tabs) {
                if !tabs.contains(selection) {
                    selection = .diary
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    isAIAvailable = RecipeDraftSource.generation.isAvailable
                }
            }
    }

    @ViewBuilder private var comparisonTabView: some View {
        #if DEBUG
        // Recreate comparisons so a previous tab role cannot leak into another layout.
        accessoryTabView.id(layout)
        #else
        accessoryTabView
        #endif
    }

    @ViewBuilder private var accessoryTabView: some View {
        if #available(iOS 26.1, *), generationInputStyle == .requestStack {
            tabView
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory(isEnabled: visibleSelection.wrappedValue == .aiRecipe) {
                    RecipeRequestAccessoryView(
                        text: $aiRecipeRequestLine,
                        request: $aiRecipeRequest,
                        isLoading: isAIRecipeLoading
                    )
                }
        } else {
            tabView
        }
    }

    @ViewBuilder var tabView: some View {
        if #available(iOS 18, *) {
            #if compiler(>=6.4)
            if #available(iOS 27, *) {
                roleBasedTabView
                    .tabViewSearchActivation(
                        layout.activatesSearchOnSelection ? .searchTabSelection : .automatic
                    )
            } else {
                roleBasedTabView
            }
            #else
            roleBasedTabView
            #endif
        } else {
            TabView(selection: visibleSelection) {
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

    @available(iOS 18, *)
    var roleBasedTabView: some View {
        TabView(selection: visibleSelection) {
            ForEach(tabs) { tab in
                Tab(value: tab, role: layout.role(for: tab)) {
                    rootView(for: tab)
                } label: {
                    tab.label
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
        incomingSearchQuery: Binding<String?> = .constant(nil)
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
            RecipeNavigationView(
                selection: $recipeSelection,
                showsAIShortcut: layout == .recipeModal
            )
        case .search:
            SearchNavigationView(
                selection: $searchSelection,
                incomingSearchQuery: $incomingSearchQuery
            )
        case .aiRecipe:
            AIRecipeNavigationView(
                inputStyle: generationInputStyle,
                request: $aiRecipeRequest,
                isLoading: $isAIRecipeLoading,
                hasPendingRequest: generationInputStyle == .requestStack
                    && !aiRecipeRequestLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
