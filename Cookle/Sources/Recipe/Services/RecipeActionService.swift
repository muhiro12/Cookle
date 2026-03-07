import Foundation
import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class RecipeActionService {
    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init(
        notificationService: NotificationService,
        requestReviewIfNeeded: @escaping CookleMutationWorkflow.ReviewRequester = {
            await MHReviewRequester.requestIfNeeded(
                policy: CookleReviewPolicy.request,
                logger: CookleApp.logger(
                    category: "ReviewFlow",
                    source: #fileID
                )
            )
        }
    ) {
        self.effectAdapter = CookleMutationWorkflow.effectAdapter(
            synchronizeNotifications: {
                await notificationService.synchronizeScheduledSuggestions()
            },
            requestReviewIfNeeded: requestReviewIfNeeded
        )
    }

    func create(
        context: ModelContext,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async -> MutationOutcome<Recipe> {
        let recipeStore = CookleMutationWorkflow.ValueStore<Recipe>()
        let effects = await CookleMutationWorkflow.run(
            name: "createRecipe",
            operation: {
                let recipe = RecipeFormService.create(
                    context: context,
                    draft: draft
                )
                recipeStore.value = recipe
                return self.recipeMutationEffects(
                    requestReview: requestReview
                )
            },
            adapter: effectAdapter
        )

        guard let recipe = recipeStore.value else {
            preconditionFailure("Recipe result was not captured.")
        }

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
        let effects = await CookleMutationWorkflow.run(
            name: "updateRecipe",
            operation: {
                RecipeFormService.update(
                    context: context,
                    recipe: recipe,
                    draft: draft
                )
                return self.recipeMutationEffects(
                    requestReview: requestReview
                )
            },
            adapter: effectAdapter
        )
        return .init(
            value: (),
            effects: effects
        )
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async -> MutationOutcome<Void> {
        let effects = await CookleMutationWorkflow.run(
            name: "deleteRecipe",
            operation: {
                RecipeService.delete(
                    context: context,
                    recipe: recipe
                )
                return self.recipeMutationEffects(
                    requestReview: false
                )
            },
            adapter: effectAdapter
        )
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
        let effects = await CookleMutationWorkflow.run(
            name: "recordOpenedRecipe",
            operation: {
                RecipeService.recordLastOpenedRecipe(recipe)
                return [
                    .recipeDataChanged
                ]
            },
            adapter: effectAdapter
        )
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
}
