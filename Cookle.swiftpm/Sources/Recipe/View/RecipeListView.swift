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

    @Binding private var selection: CookleSelectionValue?

    @State private var searchText = ""

    init(selection: Binding<CookleSelectionValue?> = .constant(nil)) {
        _selection = selection
    }

    var body: some View {
        List(recipes, id: \.self, selection: $selection) { recipe in
            if recipe.name.lowercased().contains(searchText.lowercased())
                || searchText.isEmpty {
                NavigationLink(selection: .recipe(recipe)) {
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
