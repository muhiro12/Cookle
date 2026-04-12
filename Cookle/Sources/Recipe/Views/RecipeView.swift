//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import MHPlatform
import SwiftData
import SwiftUI

struct RecipeView: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(CookleTipController.self)
    private var tipController
    @Environment(RecipeActionService.self)
    private var recipeActionService
    @Environment(CookleAppLogging.self)
    private var logging

    @AppStorage(BoolPreferenceKey.isSubscribeOn)
    private var isSubscribeOn

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
                ShareRecipeLinkButton()
                AddRecipeToTodayDiaryButton()
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
            tipController.donateDidOpenRecipeDetail()
            do {
                _ = try await recipeActionService.recordOpenedRecipe(
                    recipe
                )
            } catch {
                let recipeLogger = logging.logger(
                    category: "RecipeDetail",
                    source: #fileID
                )
                recipeLogger.error(
                    "failed to record opened recipe",
                    metadata: [
                        "error": error.localizedDescription
                    ]
                )
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        RecipeView()
            .environment(recipes[0])
    }
}
