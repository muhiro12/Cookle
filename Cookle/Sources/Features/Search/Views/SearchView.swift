//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import MHUI
import SwiftUI

struct SearchView: View {
    private enum SearchTiming {
        static let debounceMilliseconds = 250
    }

    private enum DiscoverySheet: String, Identifiable {
        case ingredient
        case category

        var id: Self {
            self
        }
    }

    @Environment(\.isPresented)
    private var isPresented

    @Binding private var recipe: Recipe?
    @Binding private var incomingSearchQuery: String?

    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchRetryID = 0
    @State private var isSearchPresented = false
    @State private var discoverySheet: DiscoverySheet?
    @State private var ingredientSelection: Ingredient?
    @State private var categorySelection: Category?
    @State private var discoveryRecipeSelection: Recipe?

    var body: some View {
        searchContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cookleTopLevelNavigationChrome(
                "Search",
                keyboardDismissMode: .immediately
            )
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                prompt: Text("Search")
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .sheet(
                item: $discoverySheet,
                onDismiss: resetDiscoverySelections
            ) { sheet in
                switch sheet {
                case .ingredient:
                    TagNavigationView<Ingredient>(
                        selection: $ingredientSelection,
                        recipeSelection: $discoveryRecipeSelection
                    )
                case .category:
                    TagNavigationView<Category>(
                        selection: $categorySelection,
                        recipeSelection: $discoveryRecipeSelection
                    )
                }
            }
            .toolbar {
                ToolbarItem {
                    discoveryMenu
                }
                ToolbarItem {
                    if isPresented {
                        CloseButton()
                    }
                }
            }
            .task(id: searchText) {
                await debounceSearch()
            }
            .task {
                applyIncomingSearchQueryIfNeeded()
            }
            .onChange(of: incomingSearchQuery) {
                applyIncomingSearchQueryIfNeeded()
            }
    }

    @ViewBuilder var searchContent: some View {
        if searchText.isEmpty {
            searchPromptPlaceholder
        } else if searchText != debouncedSearchText {
            ProgressView("Searching Recipes")
                .cookleEmptyState()
        } else {
            SearchResultsView(
                searchText: debouncedSearchText,
                selection: $recipe
            ) {
                searchRetryID += 1
            }
            .id(searchRetryID)
        }
    }

    var searchPromptPlaceholder: some View {
        ContentUnavailableView {
            Label("Search Recipes", systemImage: "magnifyingglass")
        } description: {
            Text("Search by recipe name, ingredient, or category.")
        } actions: {
            Button("Start Searching") {
                isSearchPresented = true
            }
            Button("Ingredient") {
                discoverySheet = .ingredient
            }
            Button("Category") {
                discoverySheet = .category
            }
        }
        .cookleEmptyState()
    }

    var discoveryMenu: some View {
        Menu {
            Button("Ingredient") {
                discoverySheet = .ingredient
            }
            Button("Category") {
                discoverySheet = .category
            }
        } label: {
            Label("Browse Tags", systemImage: "line.3.horizontal.decrease")
        }
    }

    init(
        selection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _recipe = selection
        _incomingSearchQuery = incomingSearchQuery
    }
}

private extension SearchView {
    func applyIncomingSearchQueryIfNeeded() {
        guard let incomingSearchQuery else {
            return
        }
        searchText = incomingSearchQuery
        isSearchPresented = true
        self.incomingSearchQuery = nil
    }

    func debounceSearch() async {
        let query = searchText
        guard !query.isEmpty else {
            debouncedSearchText = ""
            return
        }

        do {
            try await Task.sleep(
                for: .milliseconds(SearchTiming.debounceMilliseconds)
            )
            try Task.checkCancellation()
            guard query == searchText else {
                return
            }
            debouncedSearchText = query
        } catch {
            // A superseding query cancels this debounce without changing results.
            return
        }
    }

    func resetDiscoverySelections() {
        ingredientSelection = nil
        categorySelection = nil
        discoveryRecipeSelection = nil
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SearchView()
    }
}
