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
    ) async -> MutationOutcome<Recipe> {
        let effects = recipeMutationEffects(
            requestReview: requestReview
        )
        let projection =
            MHMutationProjectionStrategy<
                PersistentIdentifier,
                MutationEffect,
                PersistentIdentifier
            >
            .fixedAdapterValue(effects)

        do {
            let persistentIdentifier = try await MHMutationWorkflow.runThrowing(
                name: "createRecipe",
                operation: {
                    RecipeFormService.create(
                        context: context,
                        draft: draft
                    ).persistentModelID
                },
                adapter: effectAdapter,
                projection: projection
            )
            return .init(
                value: recipe(
                    for: persistentIdentifier,
                    context: context
                ),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "createRecipe"
            )
        }
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
        let projection = MHMutationProjectionStrategy<Void, MutationEffect, Void>.fixedAdapterValue(
            effects
        )

        do {
            let _: Void = try await MHMutationWorkflow.runThrowing(
                name: "updateRecipe",
                operation: {
                    RecipeFormService.update(
                        context: context,
                        recipe: recipe,
                        draft: draft
                    )
                },
                adapter: effectAdapter,
                projection: projection
            )
            return .init(
                value: (),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "updateRecipe"
            )
        }
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async -> MutationOutcome<Void> {
        let effects = recipeMutationEffects(
            requestReview: false
        )
        let projection = MHMutationProjectionStrategy<Void, MutationEffect, Void>.fixedAdapterValue(
            effects
        )

        do {
            let _: Void = try await MHMutationWorkflow.runThrowing(
                name: "deleteRecipe",
                operation: {
                    RecipeService.delete(
                        context: context,
                        recipe: recipe
                    )
                },
                adapter: effectAdapter,
                projection: projection
            )
            return .init(
                value: (),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "deleteRecipe"
            )
        }
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
        let effects: MutationEffect = [
            .recipeDataChanged
        ]
        let projection = MHMutationProjectionStrategy<Void, MutationEffect, Void>.fixedAdapterValue(
            effects
        )

        do {
            let _: Void = try await MHMutationWorkflow.runThrowing(
                name: "recordOpenedRecipe",
                operation: {
                    RecipeService.recordLastOpenedRecipe(recipe)
                },
                adapter: effectAdapter,
                projection: projection
            )
            return .init(
                value: (),
                effects: effects
            )
        } catch {
            unexpectedFailure(
                error,
                name: "recordOpenedRecipe"
            )
        }
    }
}

private extension RecipeActionService {
    func unexpectedFailure(
        _ error: any Error,
        name: String
    ) -> Never {
        assertionFailure(error.localizedDescription)
        preconditionFailure("Mutation unexpectedly failed: \(name)")
    }

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
