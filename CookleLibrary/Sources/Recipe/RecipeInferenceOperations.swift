/// Deterministic recipe inference helpers shared by platform inference adapters.
@preconcurrency
@MainActor
public enum RecipeInferenceOperations {
    /// Returns normalized free-form inference input.
    public static func normalizedInput(_ text: String) -> String {
        RecipeService.normalizedInferenceInput(text)
    }

    /// Returns a sanitized inference result.
    public static func sanitizedInference(
        _ inference: RecipeInferenceResult
    ) -> RecipeInferenceResult {
        RecipeService.sanitizedInference(inference)
    }

    /// Returns whether an inference result contains enough user-meaningful content.
    public static func isMeaningfulInference(
        _ inference: RecipeInferenceResult
    ) -> Bool {
        RecipeService.isMeaningfulInference(inference)
    }

    /// Returns deterministic best-effort inference for free-form text.
    public static func fallbackInference(from text: String) -> RecipeInferenceResult {
        RecipeService.fallbackInference(from: text)
    }
}
