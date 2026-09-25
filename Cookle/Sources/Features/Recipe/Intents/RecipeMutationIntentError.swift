import Foundation

enum RecipeMutationIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case recipeNotFound
    case failedToBuildEntity

    var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .recipeNotFound:
            return "Recipe not found."
        case .failedToBuildEntity:
            return "Failed to build the recipe result."
        }
    }
}
