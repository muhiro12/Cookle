import Foundation

enum RecipeMutationIntentError: LocalizedError {
    case recipeNotFound
    case failedToBuildEntity

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            return "Recipe not found."
        case .failedToBuildEntity:
            return "Failed to build the recipe result."
        }
    }
}
