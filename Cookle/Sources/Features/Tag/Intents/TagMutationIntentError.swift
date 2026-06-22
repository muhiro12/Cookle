import Foundation

enum TagMutationIntentError: LocalizedError {
    case categoryNotFound
    case ingredientNotFound

    var errorDescription: String? {
        switch self {
        case .categoryNotFound:
            return "Category not found."
        case .ingredientNotFound:
            return "Ingredient not found."
        }
    }
}
