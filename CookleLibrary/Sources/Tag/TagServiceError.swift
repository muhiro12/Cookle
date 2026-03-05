import Foundation

/// Errors thrown by tag workflows.
public enum TagServiceError: Equatable, LocalizedError {
    case emptyValue
    case ingredientInUse(String)

    public var errorDescription: String? {
        switch self {
        case .emptyValue:
            return "Value must not be empty."
        case .ingredientInUse(let value):
            return "Ingredient '\(value)' is used by existing recipes."
        }
    }
}
