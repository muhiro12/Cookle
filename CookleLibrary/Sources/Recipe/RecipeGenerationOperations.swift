import Foundation

/// Shared rules for turning creative output into an editable recipe draft.
@preconcurrency
@MainActor
public enum RecipeGenerationOperations {
    /// Generates a recipe with Private Cloud Compute without substituting another model.
    ///
    /// Unavailability and failed requests leave the input available for an explicit retry.
    /// Cancellation takes precedence over a late response or service error.
    public static func generate(
        unavailableReason: RecipeGenerationError?,
        generateWithCloud: () async throws -> RecipeInferenceResult,
        onStatus: (RecipeGenerationStatus) -> Void
    ) async throws -> RecipeInferenceResult {
        try Task.checkCancellation()
        if let unavailableReason {
            throw unavailableReason
        }

        onStatus(.privateCloudCompute)
        try Task.checkCancellation()
        do {
            let recipe = try await generateWithCloud()
            try Task.checkCancellation()
            return recipe
        } catch {
            try Task.checkCancellation()
            throw error
        }
    }

    /// Normalizes creative output and requires a name, ingredients, and steps.
    ///
    /// Unlike extraction, generated quantities and instructions need not appear
    /// in the request. This checks usable structure, not culinary correctness.
    public static func preparedDraft(
        from generated: RecipeInferenceResult
    ) -> RecipeInferenceResult? {
        var draft = RecipeInferenceOperations.sanitizedInference(generated)
        // The editor supplies row numbers. Strip generated list markers while
        // preserving quantities such as "1.5 tbsp" at the start of a step.
        draft.steps = draft.steps
            .map { step in
                step.replacingOccurrences(
                    of: #"^(?:[0-9０-９]+[.．)）]|[-*•])(?:\s+|$)"#,
                    with: "",
                    options: .regularExpression
                )
            }
            .filter { step in
                !step.isEmpty
            }
        guard !draft.name.isEmpty,
              !draft.ingredients.isEmpty,
              !draft.steps.isEmpty else {
            return nil
        }
        return draft
    }
}
