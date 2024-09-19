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

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        Group {
            if recipes.isNotEmpty {
                List(recipes, selection: $recipe) { recipe in
                    NavigationLink(value: recipe) {
                        Text(recipe.name)
                    }
                }
            } else if searchText.isNotEmpty {
                Label {
                    Text("Not Found")
                } icon: {
                    Image(systemName: "questionmark.square.dashed")
                }
                .font(.title)
                .foregroundStyle(.secondary)
            } else {
                Label {
                    Text("Please enter a search term")
                } icon: {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                }
                .font(.title)
                .foregroundStyle(.secondary)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(Text("Search"))
        .toolbar {
            if isPresented {
                ToolbarItem {
                    CloseButton()
                }
            }
        }
        .onChange(of: searchText) {
            do {
                let recipes = try context.fetch(.recipes(.nameContains(searchText)))
                let ingredients = try context.fetch(.ingredients(.valueContains(searchText)))
                let categories = try context.fetch(.categories(.valueContains(searchText)))
                self.recipes = Array(
                    Set(
                        recipes
                            + ingredients.flatMap { $0.recipes.orEmpty }
                            + categories.flatMap { $0.recipes.orEmpty }
                    )
                )
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
