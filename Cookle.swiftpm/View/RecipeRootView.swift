//
//  RecipeRootView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI
import SwiftData

struct RecipeRootView: View {
    @Query private var recipes: [Recipe]

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
                        ToolbarItem {
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
        RecipeRootView()
    }
}
