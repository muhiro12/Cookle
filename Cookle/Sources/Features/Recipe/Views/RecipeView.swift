//
//  RecipeView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import MHPlatform
import MHUI
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

    #if DEBUG
    @Environment(RecipeFormPresenter.self)
    private var recipeFormPresenter
    #endif

    @Environment(\.mhTheme)
    private var theme

    #if DEBUG
    /// Opens the cooking session for a capture run without simulated user interaction.
    @State private var isCookingPresented = CookleCaptureConfiguration.presentsCooking
    #else
    @State private var isCookingPresented = false
    #endif

    #if DEBUG
    /// Opens the edit form for a capture run without simulated user interaction.
    @State private var hasPresentedCaptureRecipeForm = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            RecipePhotosSection()
            RecipeOverview(
                servingSize: recipe.servingSize,
                cookingTime: recipe.cookingTime
            )
            MHActionGroup {
                startCookingButton
                    .buttonStyle(.mhPrimary)
                AddRecipeToTodayDiaryButton()
            }
            recipeSections
            RecipeSecondaryActions()
            RecipeProvenance(
                createdAt: recipe.createdTimestamp,
                updatedAt: recipe.modifiedTimestamp
            )
        }
        .mhScreen(title: Text(recipe.name))
        .cookleWrappingLargeTitle(Text(recipe.name))
        .cookleIdleTimerDisabled()
        .fullScreenCover(isPresented: $isCookingPresented) {
            NavigationStack {
                CookingSessionView()
            }
        }
        #if DEBUG
        .task {
            presentCaptureRecipeFormIfNeeded()
        }
        #endif
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
        RecipeIngredientsSection(presentation: .mhui)
        RecipeStepsSection(presentation: .reading)
        AdvertisementSection(.media)
        RecipeCategoriesSection(presentation: .mhui)
        RecipeNoteSection(presentation: .reading)
        RecipeDiariesSection(presentation: .mhui)
    }

    @ViewBuilder var startCookingButton: some View {
        if !recipe.steps.isEmpty {
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

    #if DEBUG
    func presentCaptureRecipeFormIfNeeded() {
        guard CookleCaptureConfiguration.presentsRecipeForm,
              !hasPresentedCaptureRecipeForm else {
            return
        }

        hasPresentedCaptureRecipeForm = true
        recipeFormPresenter.present(
            .edit,
            recipe: recipe
        )
    }
    #endif
}
