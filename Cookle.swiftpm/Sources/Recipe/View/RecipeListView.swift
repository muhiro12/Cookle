//
//  RecipeListView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Query(.recipes()) private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }

    var body: some View {
        List(recipes, id: \.self, selection: $recipe) { recipe in
            if recipe.name.lowercased().contains(searchText.lowercased())
                || searchText.isEmpty {
                NavigationLink(value: recipe) {
                    Text(recipe.name)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle(Text("Recipes"))
        .toolbar {
            ToolbarItem {
                AddRecipeButton()
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            RecipeListView()
        }
    }
}
