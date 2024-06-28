//
//  RecipeListView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Query(Recipe.descriptor) private var recipes: [Recipe]

    @Binding private var selection: Recipe?

    init(selection: Binding<Recipe?>) {
        self._selection = selection
    }

    var body: some View {
        List(recipes, id: \.self, selection: $selection) { recipe in
            Text(recipe.name)
        }
        .navigationTitle("Recipes")
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
            RecipeListView(selection: .constant(nil))
        }
    }
}
