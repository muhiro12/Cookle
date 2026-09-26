import Foundation
import SwiftData

/// Recipe form use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum RecipeFormOperations {
    /// Builds a validated draft from raw form input.
    public static func makeDraft(
        input: RecipeFormInput
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            input: input
        )
    }

    /// Indicates whether applying an inferred recipe to `input` would replace
    /// values the user entered, so the replacement needs review first.
    nonisolated public static func inferenceReplacesEnteredValues(
        in input: RecipeFormInput
    ) -> Bool {
        RecipeInferenceApplication.replacesEnteredValues(
            in: input
        )
    }

    /// Applies an inferred recipe to form input, keeping photos and the input
    /// it replaced so the application can be undone once.
    nonisolated public static func applyInference(
        _ inference: RecipeInferenceResult,
        sourceURL: URL?,
        to input: RecipeFormInput
    ) -> RecipeInferenceApplication {
        .init(
            inference: inference,
            sourceURL: sourceURL,
            replacing: input
        )
    }

    /// Creates a new recipe from a validated draft and returns follow-up hints.
    ///
    /// - Throws: An error when SwiftData cannot resolve reusable recipe resources.
    public static func createWithOutcome(
        context: ModelContext,
        draft: RecipeFormDraft
    ) throws -> MutationOutcome<Recipe> {
        try RecipeFormService.createWithOutcome(
            context: context,
            draft: draft
        )
    }

    /// Updates an existing recipe from a validated draft and returns follow-up hints.
    ///
    /// - Throws: An error when SwiftData cannot resolve reusable recipe resources.
    public static func updateWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft
    ) throws -> MutationOutcome<Recipe> {
        try RecipeFormService.updateWithOutcome(
            context: context,
            recipe: recipe,
            draft: draft
        )
    }
}
