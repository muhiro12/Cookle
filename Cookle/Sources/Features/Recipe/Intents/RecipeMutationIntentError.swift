import Foundation

enum RecipeMutationIntentError: LocalizedError {
    case recipeNotFound
    case failedToBuildEntity

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            return String(localized: "Recipe not found.")
        case .failedToBuildEntity:
            return String(localized: "Failed to build the recipe result.")
        }
    }
}
