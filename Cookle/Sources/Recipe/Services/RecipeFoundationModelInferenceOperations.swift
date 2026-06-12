import Foundation
import FoundationModels

@available(iOS 26.0, *)
enum RecipeFoundationModelInferenceOperations {
    static var inferenceInstructions: String {
        """
        You extract structured recipe form fields from recipe-like text.
        The text may come from OCR, copied recipe pages, or dictated notes.
        Return only information that is explicit or strongly implied by the input.
        Preserve the input's original language and wording where practical.
        Do not answer as a chef or rewrite the recipe into polished prose.
        Do not invent ingredients, steps, servings, cooking time, categories, or notes.
        Use 0 for unknown numeric values and empty strings or empty arrays for missing text fields.
        """
    }

    /// Infers a recipe structure from free-form text using an LLM and a conservative fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: A `RecipeInferenceResult` with best-effort fields filled.
    static func infer(text: String) async throws -> RecipeInferenceResult {
        let normalizedText = RecipeInferenceOperations.normalizedInput(text)
        guard !normalizedText.isEmpty else {
            throw RecipeInferenceError.emptyInput
        }

        let fallback = RecipeInferenceOperations.sanitizedInference(
            RecipeInferenceOperations.fallbackInference(from: normalizedText)
        )
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable:
            guard RecipeInferenceOperations.isMeaningfulInference(fallback) else {
                throw RecipeInferenceError.modelUnavailable
            }
            return fallback
        }

        let session = LanguageModelSession(
            instructions: inferenceInstructions
        )

        do {
            let inferred = try await session.respond(
                to: inferencePrompt(
                    text: normalizedText
                ),
                generating: InferredRecipe.self
            ).content
            let sanitized = RecipeInferenceOperations.sanitizedInference(inferred.recipeInferenceResult)
            if RecipeInferenceOperations.isMeaningfulInference(sanitized) {
                return sanitized
            }
        } catch {
            // Fall back to deterministic extraction below.
        }

        guard RecipeInferenceOperations.isMeaningfulInference(fallback) else {
            throw RecipeInferenceError.insufficientContent
        }
        return fallback
    }

    static func inferencePrompt(
        text: String
    ) -> String {
        """
        Extract a recipe form from the following text.
        Return only the structured fields defined by the schema.

        Text:
        \(text)
        """
    }
}
