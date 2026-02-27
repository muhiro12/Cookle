//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @Binding private var recipe: Recipe?
    @Binding private var incomingSearchQuery: String?

    @State private var recipes = [Recipe]()
    @State private var searchText = ""
    @State private var isFocused = false

    init(
        selection: Binding<Recipe?> = .constant(nil),
        incomingSearchQuery: Binding<String?> = .constant(nil)
    ) {
        _recipe = selection
        _incomingSearchQuery = incomingSearchQuery
    }

    var body: some View {
        Group {
            if recipes.isNotEmpty {
                List(recipes, selection: $recipe) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeLabel()
                            .labelStyle(.titleAndLargeIcon)
                            .environment(recipe)
                    }
                }
            } else if searchText.isNotEmpty {
                Button {
                    isFocused = true
                } label: {
                    Label {
                        Text("Not Found")
                    } icon: {
                        Image(systemName: "questionmark.square.dashed")
                    }
                }
                .foregroundStyle(.secondary)
                .offset(y: -40)
            } else {
                Button {
                    isFocused = true
                } label: {
                    Label {
                        Text("Please enter a search term")
                    } icon: {
                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    }
                }
                .foregroundStyle(.secondary)
                .offset(y: -40)
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
