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

    var body: some View {
        Group {
            if recipes.isNotEmpty {
                searchResults
            } else if searchText.isNotEmpty {
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
        .sheet(item: $discoverySheet) { sheet in
            NavigationStack {
                switch sheet {
                case .ingredient:
                    TagListView<Ingredient>(
                        selection: ingredientSelectionBinding
                    )
                    .listStyle(.insetGrouped)
                case .category:
                    TagListView<Category>(
                        selection: categorySelectionBinding
                    )
                    .listStyle(.insetGrouped)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                discoveryMenu
            }
            ToolbarItem {
                CloseButton()
                    .hidden(!isPresented)
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
        List(recipes) { recipe in
            Button {
                self.recipe = recipe
            } label: {
                RecipeLabel()
                    .labelStyle(.titleAndLargeIcon)
                    .environment(recipe)
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

    var ingredientSelectionBinding: Binding<Ingredient?> {
        .init(
            get: {
                nil
            },
            set: { ingredient in
                guard let ingredient else {
                    return
                }
                applyDiscoveryQuery(ingredient.value)
            }
        )
    }

    var categorySelectionBinding: Binding<Category?> {
        .init(
            get: {
                nil
            },
            set: { category in
                guard let category else {
                    return
                }
                applyDiscoveryQuery(category.value)
            }
        )
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

    func applyDiscoveryQuery(_ query: String) {
        searchText = query
        discoverySheet = nil
        isFocused = true
        performSearch()
    }

    func performSearch() {
        do {
            recipes = try RecipeService.search(
                context: context,
                text: searchText
            )
        } catch {
            recipes = []
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SearchView()
    }
}
