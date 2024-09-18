//
//  RecipeListView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Query(.recipes(.all)) private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    init(selection: Binding<Recipe?> = .constant(nil), descriptor: FetchDescriptor<Recipe> = .recipes(.all)) {
        _recipe = selection
        _recipes = .init(descriptor)
    }

    var body: some View {
        List(recipes, id: \.self, selection: $recipe) { recipe in
            if recipe.name.normalizedContains(searchText)
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
