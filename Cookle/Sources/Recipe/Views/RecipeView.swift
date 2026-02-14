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
            let lastOpenedRecipeID = try? recipe.id.base64Encoded()
            CookleSharedPreferences.set(lastOpenedRecipeID, for: .lastOpenedRecipeID)
            CooklePreferences.set(lastOpenedRecipeID, for: .lastOpenedRecipeID)
            CookleWidgetReloader.reloadLastOpenedRecipeWidget()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        RecipeView()
            .environment(recipes[0])
    }
}
