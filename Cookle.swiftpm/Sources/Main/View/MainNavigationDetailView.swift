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
            .navigationTitle(detail.name)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    DeleteRecipeButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    EditRecipeButton()
                }
            }
            .environment(detail)
    }
}

#Preview {
    CooklePreview { preview in
        NavigationStack {
            MainNavigationDetailView(preview.recipes[0])
        }
    }
}
