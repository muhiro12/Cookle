import Foundation
import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class RecipeActionService {
    private struct OperationResult<Value> {
        let value: Value
        let effects: MutationEffect
    }

    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init(
        notificationService: NotificationService,
        reviewFlow: MHReviewFlow
    ) {
        self.effectAdapter = CookleMutationEffectAdapter.make(
            synchronizeNotifications: {
                await notificationService.synchronizeScheduledSuggestions()
            },
            reviewFlow: reviewFlow
        )
    }

    func create(
        context: ModelContext,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async throws -> MutationOutcome<Recipe> {
        try await run(
            name: "createRecipe",
            requestReview: requestReview
        ) {
            RecipeFormService.createWithOutcome(
                context: context,
                draft: draft
            )
        }
    }

    func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async throws -> MutationOutcome<Recipe> {
        try await run(
            name: "updateRecipe",
            requestReview: requestReview
        ) {
            RecipeFormService.updateWithOutcome(
                context: context,
                recipe: recipe,
                draft: draft
            )
        }
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteRecipe",
            requestReview: false
        ) {
            RecipeService.deleteWithOutcome(
                context: context,
                recipe: recipe
            )
        }
    }

    func replaceGeneratedPhoto(
        context: ModelContext,
        recipe: Recipe,
        data: Data
    ) async throws -> MutationOutcome<Recipe> {
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

        return try await update(
            context: context,
            recipe: recipe,
            draft: updatedDraft,
            requestReview: false
        )
    }

    func recordOpenedRecipe(
        _ recipe: Recipe
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "recordOpenedRecipe",
            requestReview: false
        ) {
            RecipeService.recordLastOpenedRecipeWithOutcome(
                recipe
            )
        }
    }
}

private extension RecipeActionService {
    func run<Value>(
        name: String,
        requestReview: Bool,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let result = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                    let outcome = try operation()
                    return OperationResult(
                        value: outcome.value,
                        effects: self.recipeMutationEffects(
                            baseEffects: outcome.effects,
                            requestReview: requestReview
                        )
                )
            },
            adapter: effectAdapter,
            projection: .closures(
                afterSuccess: { result in
                    result.effects
                },
                returning: { result in
                    result
                }
            )
        )
        return .init(
            value: result.value,
            effects: result.effects
        )
    }

    func recipeMutationEffects(
        baseEffects: MutationEffect,
        requestReview: Bool
    ) -> MutationEffect {
        var effects = baseEffects

        if requestReview {
            effects.insert(.reviewPromptEligible)
        }

        return effects
    }
}
