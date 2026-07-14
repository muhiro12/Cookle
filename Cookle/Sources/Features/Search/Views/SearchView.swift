//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
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

    @Environment(\.modelContext)
    private var context
    @Environment(\.isPresented)
    private var isPresented

    @Binding private var recipe: Recipe?
    @Binding private var incomingSearchQuery: String?

    @State private var recipes = [Recipe]()
    @State private var searchText = ""
    @State private var searchErrorMessage: String?
    @State private var isSearching = false
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
                await performSearch()
            }
            .task {
                applyIncomingSearchQueryIfNeeded()
            }
            .onChange(of: incomingSearchQuery) {
                applyIncomingSearchQueryIfNeeded()
            }
    }

    @ViewBuilder var searchContent: some View {
        if isSearching {
            ProgressView("Searching Recipes")
        } else if let searchErrorMessage {
            ContentUnavailableView {
                Label(
                    "Cannot Search Recipes",
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(searchErrorMessage)
            } actions: {
                Button("Try Again") {
                    Task {
                        await performSearch(shouldDebounce: false)
                    }
                }
            }
        } else if !recipes.isEmpty {
            searchResults
        } else if !searchText.isEmpty {
            notFoundPlaceholder
        } else {
            searchPromptPlaceholder
        }
    }

    var searchResults: some View {
        List(recipes) { rowRecipe in
            Button {
                $recipe.cookleSelectForNavigation(
                    rowRecipe
                )
            } label: {
                RecipeLabel()
                    .labelStyle(.titleAndLargeIcon)
                    .environment(rowRecipe)
                    .cookleButtonRowContent()
            }
            .buttonStyle(.plain)
        }
    }

    var notFoundPlaceholder: some View {
        ContentUnavailableView.search(text: searchText)
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
            Label("Browse Tags", systemImage: "line.3.horizontal.decrease.circle")
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

    func performSearch(
        shouldDebounce: Bool = true
    ) async {
        let query = searchText
        guard !query.isEmpty else {
            recipes = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        defer {
            if query == searchText {
                isSearching = false
            }
        }

        do {
            if shouldDebounce {
                try await Task.sleep(
                    for: .milliseconds(SearchTiming.debounceMilliseconds)
                )
            }
            try Task.checkCancellation()
            let results = try RecipeOperations.search(
                context: context,
                text: query
            )
            guard query == searchText else {
                return
            }
            recipes = results
            searchErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard query == searchText else {
                return
            }
            recipes = []
            searchErrorMessage = error.localizedDescription
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
