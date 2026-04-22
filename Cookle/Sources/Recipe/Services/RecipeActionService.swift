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
    private let saveLogger: MHLogger

    init(
        notificationService: NotificationService,
        reviewFlow: MHReviewFlow,
        saveLogger: MHLogger
    ) {
        self.effectAdapter = CookleMutationEffectAdapter.make(
            synchronizeNotifications: {
                await notificationService.synchronizeScheduledSuggestions()
            },
            reviewFlow: reviewFlow
        )
        self.saveLogger = saveLogger
    }

    @discardableResult
    func create(
        context: ModelContext,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async throws -> MutationOutcome<Recipe> {
        let summary = RecipeSaveLogging.makeSummary(
            operation: "create",
            context: context,
            draft: draft
        )
        return try await run(
            name: "createRecipe",
            requestReview: requestReview,
            saveSummary: summary
        ) {
            RecipeFormService.createWithOutcome(
                context: context,
                draft: draft
            )
        }
    }

    @discardableResult
    func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async throws -> MutationOutcome<Recipe> {
        let summary = RecipeSaveLogging.makeSummary(
            operation: "update",
            context: context,
            draft: draft
        )
        return try await run(
            name: "updateRecipe",
            requestReview: requestReview,
            saveSummary: summary
        ) {
            RecipeFormService.updateWithOutcome(
                context: context,
                recipe: recipe,
                draft: draft
            )
        }
    }

    @discardableResult
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

    @discardableResult
    func removePhoto(
        context: ModelContext,
        recipe: Recipe,
        photoObject: PhotoObject
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "removeRecipePhoto",
            requestReview: false
        ) {
            RecipeService.removePhotoWithOutcome(
                context: context,
                recipe: recipe,
                photoObject: photoObject
            )
        }
    }

    @discardableResult
    func replaceGeneratedPhoto(
        context: ModelContext,
        recipe: Recipe,
        data: Data
    ) async throws -> MutationOutcome<Recipe> {
        let updatedDraft = recipeDraft(
            for: recipe,
            photos: [
                .init(
                    data: data.compressed(),
                    source: .imagePlayground
                )
            ]
        )

        return try await update(
            context: context,
            recipe: recipe,
            draft: updatedDraft,
            requestReview: false
        )
    }

    @discardableResult
    func appendPhoto(
        context: ModelContext,
        recipe: Recipe,
        data: Data,
        source: PhotoSource
    ) async throws -> MutationOutcome<Recipe> {
        let updatedDraft = recipeDraft(
            for: recipe,
            photos: recipe.orderedPhotos.map { photo in
                .init(
                    data: photo.data,
                    source: photo.source
                )
            } + [
                .init(
                    data: data.compressed(),
                    source: source
                )
            ]
        )

        return try await update(
            context: context,
            recipe: recipe,
            draft: updatedDraft,
            requestReview: false
        )
    }

    @discardableResult
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
    func recipeDraft(
        for recipe: Recipe,
        photos: [PhotoData]
    ) -> RecipeFormDraft {
        .init(
            name: recipe.name,
            photos: photos,
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
    }

    func run<Value>(
        name: String,
        requestReview: Bool,
        saveSummary: RecipeSaveLogging.Summary? = nil,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        do {
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
            if let saveSummary {
                RecipeSaveLogging.logSuccess(
                    logger: saveLogger,
                    summary: saveSummary
                )
            }
            return .init(
                value: result.value,
                effects: result.effects
            )
        } catch {
            if let saveSummary {
                RecipeSaveLogging.logFailure(
                    logger: saveLogger,
                    summary: saveSummary,
                    error: error
                )
            }
            throw error
        }
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
