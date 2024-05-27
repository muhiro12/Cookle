//
//  RecipeNavigationView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/10.
//

import SwiftUI

struct RecipeNavigationView: View {
    @State private var detail: Recipe?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            RecipeListView(selection: $detail)
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
        .onTabSelected {
            guard $0 == .recipe,
                  $1 == .recipe else {
                return
            }
            detail = nil
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        RecipeNavigationView()
            .environment(TabController(initialTab: .recipe))
    }
}
