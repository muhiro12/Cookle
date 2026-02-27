import Foundation

/// Validation errors for recipe form input.
public enum RecipeFormValidationError: Equatable, LocalizedError, Sendable {
    case emptyName
    case invalidServingSize(String)
    case invalidCookingTime(String)

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Recipe name cannot be empty."
        case .invalidServingSize(let value):
            return "Serving size is invalid: \(value)"
        case .invalidCookingTime(let value):
            return "Cooking time is invalid: \(value)"
        }
    }
}
