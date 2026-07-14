import Foundation

enum TagMutationIntentError: LocalizedError {
    case ambiguousCategory(String)
    case ambiguousIngredient(String)
    case categoryNotFound
    case ingredientNotFound

    var errorDescription: String? {
        switch self {
        case .ambiguousCategory(let value):
            return String.localizedStringWithFormat(
                String(
                    localized: "Cookle has multiple categories named %@. Open Cookle and merge the duplicates before running this shortcut again."
                ),
                value
            )
        case .ambiguousIngredient(let value):
            return String.localizedStringWithFormat(
                String(
                    localized: "Cookle has multiple ingredients named %@. Open Cookle and merge the duplicates before running this shortcut again."
                ),
                value
            )
        case .categoryNotFound:
            return "Category not found."
        case .ingredientNotFound:
            return "Ingredient not found."
        }
    }
}
