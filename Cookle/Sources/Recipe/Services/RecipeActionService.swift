import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RecipeActionService {
    private let notificationService: NotificationService
    private let requestReviewIfNeeded: CookleReviewRequester

    init(
        notificationService: NotificationService,
        requestReviewIfNeeded: @escaping CookleReviewRequester = MainReviewService.requestIfNeeded
    ) {
        self.notificationService = notificationService
        self.requestReviewIfNeeded = requestReviewIfNeeded
    }

    func create(
        context: ModelContext,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async -> MutationOutcome<Recipe> {
        let recipe = RecipeFormService.create(
            context: context,
            draft: draft
        )
        let effects = recipeMutationEffects(
            requestReview: requestReview
        )
        await applyEffects(effects)
        return .init(
            value: recipe,
            effects: effects
        )
    }

    func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async -> MutationOutcome<Void> {
        RecipeFormService.update(
            context: context,
            recipe: recipe,
            draft: draft
        )
        let effects = recipeMutationEffects(
            requestReview: requestReview
        )
        await applyEffects(effects)
        return .init(
            value: (),
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async -> MutationOutcome<Void> {
        RecipeService.delete(
            context: context,
            recipe: recipe
        )
        let effects = recipeMutationEffects(
            requestReview: false
        )
        await applyEffects(effects)
        return .init(
            value: (),
            effects: effects
        )
    }

    func replaceGeneratedPhoto(
        context: ModelContext,
        recipe: Recipe,
        data: Data
    ) async -> MutationOutcome<Void> {
        let updatedDraft = RecipeFormDraft(
            name: recipe.name,
            photos: [
                .init(
                    data: data.compressed(),
                    source: .imagePlayground
                )
            ],
            servingSize: recipe.servingSize,
            cookingTime: recipe.cookingTime,
            ingredients: recipe.ingredientObjects.orEmpty.sorted().compactMap { object in
                guard let ingredient = object.ingredient else {
                    return nil
                }
                return .init(
                    ingredient: ingredient.value,
                    amount: object.amount
                )
            },
            steps: recipe.steps,
            categories: recipe.categories.orEmpty.map(\.value),
            note: recipe.note
        )

        return await update(
            context: context,
            recipe: recipe,
            draft: updatedDraft,
            requestReview: false
        )
    }

    func recordOpenedRecipe(
        _ recipe: Recipe
    ) async -> MutationOutcome<Void> {
        RecipeService.recordLastOpenedRecipe(recipe)
        let effects: MutationEffect = [
            .recipeDataChanged
        ]
        await applyEffects(effects)
        return .init(
            value: (),
            effects: effects
        )
    }
}

private extension RecipeActionService {
    func recipeMutationEffects(
        requestReview: Bool
    ) -> MutationEffect {
        var effects: MutationEffect = [
            .recipeDataChanged,
            .notificationPlanChanged
        ]

        if requestReview {
            effects.insert(.reviewPromptEligible)
        }

        return effects
    }

    func applyEffects(
        _ effects: MutationEffect
    ) async {
        if effects.contains(.recipeDataChanged) {
            CookleWidgetReloader.reloadRecipeWidgets()
        }

        if effects.contains(.notificationPlanChanged) {
            await notificationService.synchronizeScheduledSuggestions()
        }

        if effects.contains(.reviewPromptEligible) {
            _ = await requestReviewIfNeeded()
        }
    }
}
