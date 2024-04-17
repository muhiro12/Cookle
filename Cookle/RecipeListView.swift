//
//  RecipeListView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct RecipeListView: View {
    @Binding private var selection: Recipe?

    private let recipes: [Recipe]

    init(_ recipes: [Recipe], selection: Binding<Recipe?>) {
        self.recipes = recipes
        self._selection = selection
    }
    
    var body: some View {
        List(recipes, id: \.self, selection: $selection) { recipe in
            Text(recipe.name)
        }
    }
}

#Preview {
    ModelContainerPreview { preview in
        RecipeListView(preview.recipes, selection: .constant(nil))
    }
}
