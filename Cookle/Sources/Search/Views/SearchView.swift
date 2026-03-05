//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    private enum Layout {
        static let placeholderOffsetY = CGFloat(
            -(Double("40") ?? .zero)
        )
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
        .navigationTitle(Text("Search"))
        .toolbar {
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
        List(recipes, selection: $recipe) { recipe in
            NavigationLink(value: recipe) {
                RecipeLabel()
                    .labelStyle(.titleAndLargeIcon)
                    .environment(recipe)
            }
        }
    }

    var notFoundPlaceholder: some View {
        placeholderButton(
            title: "Not Found",
            systemImage: "questionmark.square.dashed"
        )
    }

    var searchPromptPlaceholder: some View {
        placeholderButton(
            title: "Please enter a search term",
            systemImage: "rectangle.and.pencil.and.ellipsis"
        )
    }

    init(
        selection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _recipe = selection
        _incomingSearchQuery = incomingSearchQuery
    }

    func placeholderButton(
        title: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Button {
            isFocused = true
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(.secondary)
        .offset(y: Layout.placeholderOffsetY)
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
            recipes = try RecipeService.search(
                context: context,
                text: searchText
            )
        } catch {
            recipes = []
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SearchView()
    }
}
