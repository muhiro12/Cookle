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
        let effects = recipeMutationEffects(
            requestReview: requestReview
        )
        let afterSuccess: @MainActor @Sendable (PersistentIdentifier) -> MutationEffect = { _ in
            effects
        }
        let mutationOutcome = await CookleMutationWorkflow.run(
            name: "createRecipe",
            operation: {
                RecipeFormService.create(
                    context: context,
                    draft: draft
                ).persistentModelID
            },
            adapter: effectAdapter,
            afterSuccess: afterSuccess
        )
        return .init(
            value: recipe(
                for: mutationOutcome.value,
                context: context
            ),
            effects: mutationOutcome.effects
        )
    }

    func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async -> MutationOutcome<Void> {
        let effects = recipeMutationEffects(
            requestReview: requestReview
        )
        let afterSuccess: @MainActor @Sendable () -> MutationEffect = {
            effects
        }
        return await CookleMutationWorkflow.run(
            name: "updateRecipe",
            operation: {
                RecipeFormService.update(
                    context: context,
                    recipe: recipe,
                    draft: draft
                )
            },
            adapter: effectAdapter,
            afterSuccess: afterSuccess
        )
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async -> MutationOutcome<Void> {
        let effects = recipeMutationEffects(
            requestReview: false
        )
        let afterSuccess: @MainActor @Sendable () -> MutationEffect = {
            effects
        }
        return await CookleMutationWorkflow.run(
            name: "deleteRecipe",
            operation: {
                RecipeService.delete(
                    context: context,
                    recipe: recipe
                )
            },
            adapter: effectAdapter,
            afterSuccess: afterSuccess
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
        let afterSuccess: @MainActor @Sendable () -> MutationEffect = {
            [
                .recipeDataChanged
            ]
        }
        return await CookleMutationWorkflow.run(
            name: "recordOpenedRecipe",
            operation: {
                RecipeService.recordLastOpenedRecipe(recipe)
            },
            adapter: effectAdapter,
            afterSuccess: afterSuccess
        )
    }
}

private extension RecipeActionService {
    func recipe(
        for persistentIdentifier: PersistentIdentifier,
        context: ModelContext
    ) -> Recipe {
        guard let recipe = context.model(
            for: persistentIdentifier
        ) as? Recipe else {
            preconditionFailure("Recipe result was not resolved.")
        }
        return recipe
    }

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
