import Foundation

/// Error surfaced when ingredient-based ideas cannot be produced safely.
public enum RecipeIdeaSuggestionError: LocalizedError, Equatable, Sendable {
    case emptyIngredients
    case insufficientContent

    public var errorDescription: String? {
        switch self {
        case .emptyIngredients:
            return "Choose at least one ingredient first."
        case .insufficientContent:
            return "Couldn't suggest useful ideas from those ingredients."
        }
    }
}
