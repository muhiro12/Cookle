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
            AdvertisementSection(.medium)
                .hidden(isSubscribeOn)
            RecipeCategoriesSection()
            RecipeNoteSection()
            RecipeDiariesSection()
            RecipeCreatedAtSection()
            RecipeUpdatedAtSection()
            Section {
                EditRecipeButton()
                DuplicateRecipeButton()
                DeleteRecipeButton()
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                EditRecipeButton()
            }
        }
        .task {
            lastOpenedRecipeID = recipe.id
            UIApplication.shared.isIdleTimerDisabled = true
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
