//
//  MainNavigationDetailView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/28.
//

import SwiftUI

struct MainNavigationDetailView: View {
    private var detail: Recipe

    init(_ detail: Recipe) {
        self.detail = detail
    }

    var body: some View {
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

#Preview {
    ModelContainerPreview { preview in
        MainNavigationDetailView(preview.recipes[0])
    }
}
