#if DEBUG
import SwiftUI

/// A separate modal keeps experimental navigation out of the production scene.
@available(iOS 26, *)
struct AIInputComparisonView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var layout = AIInputComparisonLayout.tabs
    @State private var navigationModel = MainNavigationModel()
    @State private var preferredColumn = NavigationSplitViewColumn.detail
    @State private var request = ""
    @State private var preference = ""
    @State private var isLoading = false
    @State private var hasSelectedInitialTab = false

    private var tabs: [MainTab] {
        MainTab.displayedTabs(includesAI: RecipeDraftSource.generation.isAvailable)
    }

    var body: some View {
        comparisonContent
            .environment(navigationModel)
            .task {
                if !hasSelectedInitialTab {
                    hasSelectedInitialTab = true
                    navigationModel.selectedTab = tabs.contains(.aiRecipe) ? .aiRecipe : .diary
                }
            }
    }

    @ViewBuilder private var comparisonContent: some View {
        if layout == .tabs {
            @Bindable var navigationModel = navigationModel

            TabView(selection: $navigationModel.selectedTab) {
                ForEach(tabs) { tab in
                    Tab(value: tab, role: role(for: tab)) {
                        navigationScreen(for: tab)
                    } label: {
                        tab.label
                    }
                }
            }
        } else {
            NavigationSplitView(preferredCompactColumn: $preferredColumn) {
                List(selection: sidebarSelection) {
                    ForEach(tabs) { tab in
                        NavigationLink(value: tab) {
                            tab.label
                        }
                    }
                }
                .navigationTitle(Text(verbatim: "Cookle"))
                .toolbar {
                    comparisonToolbar
                }
            } detail: {
                navigationScreen(for: navigationModel.selectedTab)
            }
        }
    }

    private var sidebarSelection: Binding<MainTab?> {
        .init(
            get: {
                navigationModel.selectedTab
            },
            set: { tab in
                if let tab {
                    navigationModel.selectedTab = tab
                    preferredColumn = .detail
                }
            }
        )
    }

    @ToolbarContentBuilder private var comparisonToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Compare AI Input", selection: $layout) {
                    ForEach(AIInputComparisonLayout.allCases) { layout in
                        Text(layout.title).tag(layout)
                    }
                }
                Button("Close", systemImage: "xmark") {
                    dismiss()
                }
            } label: {
                Label("Compare AI Input", systemImage: "rectangle.split.2x1")
            }
            .disabled(isLoading)
            .accessibilityIdentifier("aiInputComparisonLayout")
        }
    }
}

@available(iOS 26, *)
private extension AIInputComparisonView {
    func role(for tab: MainTab) -> TabRole? {
        #if compiler(>=6.4)
        if #available(iOS 27, *), tab == .aiRecipe {
            return .prominent
        }
        #endif
        return nil
    }

    func navigationScreen(for tab: MainTab) -> some View {
        @Bindable var navigationModel = navigationModel

        return NavigationStack {
            screen(for: tab)
                .toolbar {
                    comparisonToolbar
                }
                .navigationDestination(item: $navigationModel.selectedRecipe) { recipe in
                    RecipeView().environment(recipe)
                }
                .navigationDestination(item: $navigationModel.selectedDiary) { diary in
                    DiaryView(selection: $navigationModel.selectedDiaryRecipe).environment(diary)
                }
                .navigationDestination(item: $navigationModel.selectedDiaryRecipe) { recipe in
                    RecipeView().environment(recipe)
                }
                .navigationDestination(item: $navigationModel.selectedPhoto) { photo in
                    PhotoView(
                        photoSelection: $navigationModel.selectedPhoto,
                        recipeSelection: $navigationModel.selectedSearchRecipe
                    )
                    .environment(photo)
                }
                .navigationDestination(item: $navigationModel.selectedSearchRecipe) { recipe in
                    RecipeView().environment(recipe)
                }
        }
    }

    @ViewBuilder
    func screen(for tab: MainTab) -> some View {
        @Bindable var navigationModel = navigationModel

        switch tab {
        case .diary:
            DiaryListView(selection: $navigationModel.selectedDiary)
        case .recipe:
            RecipeListView(selection: $navigationModel.selectedRecipe)
        case .photo:
            PhotoListView(selection: $navigationModel.selectedPhoto)
        case .search:
            SearchView(
                selection: $navigationModel.selectedSearchRecipe,
                incomingSearchQuery: $navigationModel.incomingSearchQuery
            )
        case .aiRecipe:
            AIInputComparisonComposer(
                layout: layout,
                request: $request,
                preference: $preference,
                isLoading: $isLoading
            )
        }
    }
}
#endif
