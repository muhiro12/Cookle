import Foundation

/// Error surfaced when recipe text cannot be inferred safely enough to prefill the form.
public enum RecipeInferenceError: LocalizedError, Equatable, Sendable {
    case emptyInput
    case insufficientContent
    case modelUnavailable

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste or import some recipe text first."
        case .insufficientContent:
            return """
                Couldn't extract enough recipe details from the text.
                Try including the title, ingredients, or steps.
                """
        case .modelUnavailable:
            return "Apple Intelligence is not available right now."
        }
    }
}
