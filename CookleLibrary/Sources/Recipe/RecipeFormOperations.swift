import SwiftData

/// Recipe form use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum RecipeFormOperations {
    // swiftlint:disable function_parameter_count
    /// Builds a validated draft from raw form input.
    public static func makeDraft(
        name: String,
        photos: [PhotoData],
        servingSize: String,
        cookingTime: String,
        ingredients: [RecipeFormIngredientInput],
        steps: [String],
        categories: [String],
        note: String
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    /// Builds a validated draft from App Intent style text input.
    public static func makeDraft(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredientsText: String,
        stepsText: String,
        categoriesText: String,
        note: String
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: name,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredientsText: ingredientsText,
            stepsText: stepsText,
            categoriesText: categoriesText,
            note: note
        )
    }
    // swiftlint:enable function_parameter_count

    /// Creates a new recipe from a validated draft and returns follow-up hints.
    public static func createWithOutcome(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> MutationOutcome<Recipe> {
        RecipeFormService.createWithOutcome(
            context: context,
            draft: draft
        )
    }

    /// Updates an existing recipe from a validated draft and returns follow-up hints.
    public static func updateWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft
    ) -> MutationOutcome<Recipe> {
        RecipeFormService.updateWithOutcome(
            context: context,
            recipe: recipe,
            draft: draft
        )
    }
}
