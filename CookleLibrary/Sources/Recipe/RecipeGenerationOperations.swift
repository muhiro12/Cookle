import Foundation

/// Shared rules for turning creative output into an editable recipe draft.
@preconcurrency
@MainActor
public enum RecipeGenerationOperations {
    /// Generates with the selected policy and reports each actual processing method.
    ///
    /// Only a typed recoverable cloud failure permits one local attempt. A local-only
    /// choice, cancellation, or other error never starts a cloud request or retry loop.
    public static func generate(
        onDeviceOnly: Bool,
        cloudUnavailableReason: RecipeGenerationStatus.FallbackReason?,
        generateWithCloud: () async throws -> RecipeInferenceResult,
        generateOnDevice: () async throws -> RecipeInferenceResult,
        onStatus: (RecipeGenerationStatus) -> Void
    ) async throws -> RecipeInferenceResult {
        try Task.checkCancellation()
        var fallbackReason = cloudUnavailableReason
        if !onDeviceOnly, fallbackReason == nil {
            onStatus(.privateCloudCompute)
            try Task.checkCancellation()
            do {
                let recipe = try await generateWithCloud()
                try Task.checkCancellation()
                return recipe
            } catch {
                try Task.checkCancellation()
                guard let reason = error as? RecipeGenerationStatus.FallbackReason else {
                    throw error
                }
                fallbackReason = reason
            }
        }

        try Task.checkCancellation()
        onStatus(.onDevice(fallbackReason: onDeviceOnly ? nil : fallbackReason))
        try Task.checkCancellation()
        let recipe = try await generateOnDevice()
        try Task.checkCancellation()
        return recipe
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
