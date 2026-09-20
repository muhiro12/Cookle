import CookleLibrary
import Foundation

enum IngredientDeleteCopy {
    static func title(for ingredient: Ingredient) -> String {
        String(localized: "Delete \(ingredient.value)")
    }

    static func confirmationDialog(for ingredient: Ingredient) -> String {
        "\(title(for: ingredient))? \(message(for: ingredient))"
    }

    static func message(for _: Ingredient) -> String {
        String(
            localized: "This removes the unused ingredient record. No recipe ingredient rows will be removed."
        )
    }

    static func inUseMessage(for ingredient: Ingredient) -> String {
        let recipeCount = (ingredient.recipes ?? []).count
        if recipeCount == 1 {
            return String(
                localized: """
                Delete is available only when no recipes use this ingredient. \
                \(ingredient.value) is still used by one recipe.
                """
            )
        }

        return String(
            localized: """
            Delete is available only when no recipes use this ingredient. \
            \(ingredient.value) is still used by \(recipeCount) recipes.
            """
        )
    }

    static func rejectionDialog(for ingredient: Ingredient) -> String {
        String(localized: "Cannot delete \(ingredient.value).") + " " + inUseMessage(for: ingredient)
    }

    static func successDialog(for ingredient: Ingredient) -> String {
        String(localized: "Deleted \(ingredient.value)")
    }
}
