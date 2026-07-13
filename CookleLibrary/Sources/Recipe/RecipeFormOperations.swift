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
