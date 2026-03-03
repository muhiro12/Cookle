import Foundation
import FoundationModels

/// Errors returned while generating a recipe from ingredients.
@available(iOS 26.0, *)
public enum IngredientRecipeGenerationError: LocalizedError, Sendable {
    case emptyIngredients
    case modelUnavailable(SystemLanguageModel.Availability.UnavailableReason?)
    case invalidResponse
    case disallowedIngredients([String])

    public var errorDescription: String? {
        switch self {
        case .emptyIngredients:
            "At least one ingredient is required."
        case .modelUnavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                "This device does not support on-device recipe generation."
            case .appleIntelligenceNotEnabled:
                "Apple Intelligence must be enabled to generate recipes on-device."
            case .modelNotReady:
                "The on-device model is still preparing. Try again later."
            case .none:
                "The on-device model is unavailable right now."
            case .some:
                "The on-device model is unavailable right now."
            }
        case .invalidResponse:
            "The generated recipe response was invalid."
        case .disallowedIngredients(let ingredients):
            "The generated recipe used ingredients outside the allowed set: \(ingredients.joined(separator: ", "))."
        }
    }
}
