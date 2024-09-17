//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import SwiftData
import SwiftUI

struct RecipeView: View {
    @Environment(Recipe.self) private var recipe

    @AppStorage(.lastOpenedRecipeID) private var lastOpenedRecipeID
    @AppStorage(.isSubscribeOn) private var isSubscribeOn

    var body: some View {
        List {
            RecipePhotosSection()
            RecipeServingSizeSection()
            RecipeCookingTimeSection()
            RecipeIngredientsSection()
            RecipeStepsSection()
            if !isSubscribeOn {
                AdvertisementSection(.medium)
            }
            RecipeCategoriesSection()
            RecipeNoteSection()
            RecipeDiariesSection()
            RecipeCreatedAtSection()
            RecipeUpdatedAtSection()
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                DeleteRecipeButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                EditRecipeButton()
            }
        }
        .task {
            lastOpenedRecipeID = recipe.id
            UIApplication.shared.isIdleTimerDisabled = true
            try? await Task.sleep(for: .seconds(60 * 10))
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    CooklePreview { preview in
        NavigationStack {
            RecipeView()
                .environment(preview.recipes[0])
        }
    }
}
