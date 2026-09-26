import Foundation

enum TagMutationIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case ambiguousCategory(String)
    case ambiguousIngredient(String)
    case categoryNotFound
    case ingredientNotFound
    case ingredientInUse(String)

    var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .ambiguousCategory(let value):
            return """
                Cookle has multiple categories named \(value). Open Cookle and merge the duplicates before \
                running this shortcut again.
                """
        case .ambiguousIngredient(let value):
            return """
                Cookle has multiple ingredients named \(value). Open Cookle and merge the duplicates before \
                running this shortcut again.
                """
        case .categoryNotFound:
            return "Category not found."
        case .ingredientNotFound:
            return "Ingredient not found."
        case .ingredientInUse(let value):
            return "Ingredient \(value) is still used by recipes and cannot be deleted."
        }
    }
}
