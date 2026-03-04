import Foundation
import FoundationModels

/// Errors returned while summarizing a recipe for list previews.
@available(iOS 26.0, *)
public enum RecipeSummaryError: LocalizedError, Sendable {
    case emptyRecipe
    case modelUnavailable(SystemLanguageModel.Availability.UnavailableReason?)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .emptyRecipe:
            "At least one recipe field is required."
        case .modelUnavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                "This device does not support on-device recipe summaries."
            case .appleIntelligenceNotEnabled:
                "Apple Intelligence must be enabled to generate recipe summaries on-device."
            case .modelNotReady:
                "The on-device model is still preparing. Try again later."
            case .none:
                "The on-device model is unavailable right now."
            case .some:
                "The on-device model is unavailable right now."
            }
        case .invalidResponse:
            "The generated recipe summary response was invalid."
        }
    }
}
