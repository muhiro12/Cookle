//
//  RecipeNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI
import SwiftData

struct RecipeNavigationView: View {
    @Query(Recipe.descriptor) private var recipes: [Recipe]

    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView {
            RecipeListView(recipes, selection: $detail)
                .toolbar {
                    ToolbarItem {
                        AddRecipeButton()
                    }
                }
                .navigationTitle("Recipe")
        } detail: {
            if let detail {
                RecipeView()
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            DeleteRecipeButton()
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            EditRecipeButton()
                        }
                    }
                    .navigationTitle(detail.name)
                    .environment(detail)
            }
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        RecipeNavigationView()
    }
}
