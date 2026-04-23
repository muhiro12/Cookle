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
    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(RecipeActionService.self)
    private var recipeActionService
    @Environment(CookleAppLogging.self)
    private var logging

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @State private var isCookingPresented = false

    var body: some View {
        List {
            recipeSections
            recipeActionSection
        }
        .navigationTitle(recipe.name)
        .cookleIdleTimerDisabled()
        .fullScreenCover(isPresented: $isCookingPresented) {
            NavigationStack {
                CookingSessionView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                EditRecipeButton()
            }
        }
        .task {
            do {
                try await recipeActionService.recordOpenedRecipe(
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
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        RecipeView()
            .environment(recipes[0])
            .environment(
                CookingSessionStore(
                    persistsSnapshot: false
                )
            )
    }
}

private extension RecipeView {
    @ViewBuilder var recipeSections: some View {
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
    }

    var recipeActionSection: some View {
        Section {
            startCookingButton
            if #available(iOS 26.0, *) {
                QuickRecipeVersionButton()
            }
            ToggleRecipeFavoriteButton()
            ShareRecipeLinkButton()
            AddRecipeToTodayDiaryButton()
            EditRecipeButton()
            DuplicateRecipeButton()
            DeleteRecipeButton()
        } footer: {
            Text(shareRecipeLinkFooter)
        }
    }

    @ViewBuilder var startCookingButton: some View {
        if recipe.steps.isNotEmpty {
            Button {
                startOrResumeCooking()
            } label: {
                Label {
                    Text(cookingButtonTitle)
                } icon: {
                    Image(systemName: "fork.knife.circle")
                        .accessibilityHidden(true)
                }
            }
        }
    }

    var cookingButtonTitle: String {
        cookingSessionStore.isActiveSession(
            for: recipe
        )
        ? String(localized: "Resume Cooking")
        : String(localized: "Start Cooking")
    }

    var shareRecipeLinkFooter: String {
        String(localized: "recipe.shareLink.footer")
    }

    func startOrResumeCooking() {
        if cookingSessionStore.isActiveSession(
            for: recipe
        ) == false {
            cookingSessionStore.startSession(
                for: recipe
            )
        }

        isCookingPresented = true
    }
}
