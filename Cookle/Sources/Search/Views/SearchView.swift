//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI

struct SearchView: View {
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
    @State private var isFocused = false
    @State private var discoverySheet: DiscoverySheet?
    @State private var ingredientSelection: Ingredient?
    @State private var categorySelection: Category?
    @State private var discoveryRecipeSelection: Recipe?

    var body: some View {
        Group {
            if !recipes.isEmpty {
                searchResults
            } else if !searchText.isEmpty {
                notFoundPlaceholder
            } else {
                searchPromptPlaceholder
            }
        }
        .searchable(text: $searchText, isPresented: $isFocused)
        .cookleTopLevelNavigationChrome(
            "Search",
            keyboardDismissMode: .immediately
        )
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
        .onChange(of: searchText) {
            performSearch()
        }
        .task {
            applyIncomingSearchQueryIfNeeded()
        }
        .onChange(of: incomingSearchQuery) {
            applyIncomingSearchQueryIfNeeded()
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
                isFocused = true
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
            Image(systemName: "line.3.horizontal.decrease.circle")
                .accessibilityLabel("Browse Tags")
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
        isFocused = true
        self.incomingSearchQuery = nil
        performSearch()
    }

    func performSearch() {
        do {
            recipes = try RecipeOperations.search(
                context: context,
                text: searchText
            )
        } catch {
            recipes = []
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
