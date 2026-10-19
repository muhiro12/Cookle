/// Shared rules for turning creative output into an editable recipe draft.
@preconcurrency
@MainActor
public enum RecipeGenerationOperations {
    /// Normalizes creative output and requires a name, ingredients, and steps.
    ///
    /// Unlike extraction, generated quantities and instructions need not appear
    /// in the request. This checks usable structure, not culinary correctness.
    public static func preparedDraft(
        from generated: RecipeInferenceResult
    ) -> RecipeInferenceResult? {
        let draft = RecipeInferenceOperations.sanitizedInference(generated)
        guard !draft.name.isEmpty,
              !draft.ingredients.isEmpty,
              !draft.steps.isEmpty else {
            return nil
        }
        return draft
    }
}
