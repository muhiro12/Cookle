//
//  SearchView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct SearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.isPresented) private var isPresented

    @Binding private var recipe: Recipe?

    @State private var recipes = [Recipe]()
    @State private var searchText = ""
    @State private var isFocused = false

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
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
            do {
                var models = try context.fetch(
                    .recipes(.nameContains(searchText))
                )
                let ingredients = try context.fetch(
                    searchText.count < 3
                        ? .ingredients(.valueIs(searchText))
                        : .ingredients(.valueContains(searchText))
                )
                let categories = try context.fetch(
                    searchText.count < 3
                        ? .categories(.valueIs(searchText))
                        : .categories(.valueContains(searchText))
                )
                models += ingredients.flatMap(\.recipes.orEmpty)
                models += categories.flatMap(\.recipes.orEmpty)
                models = Array(Set(models))
                recipes = models
            } catch {}
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            SearchView()
        }
    }
}
