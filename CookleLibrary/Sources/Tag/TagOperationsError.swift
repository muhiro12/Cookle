import Foundation

/// Errors thrown by tag workflows.
public enum TagOperationsError: Equatable, LocalizedError {
    case emptyValue
    case ingredientInUse(String)

    public var errorDescription: String? {
        switch self {
        case .emptyValue:
            return "Value must not be empty."
        case .ingredientInUse(let value):
            return "Ingredient \(value) is still used by recipes and cannot be deleted."
        }
    }
}
