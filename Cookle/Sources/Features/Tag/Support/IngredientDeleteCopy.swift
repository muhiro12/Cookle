import CookleLibrary

enum IngredientDeleteCopy {
    static func title(for ingredient: Ingredient) -> String {
        "Delete \(ingredient.value)"
    }

    static func confirmationDialog(for ingredient: Ingredient) -> String {
        "\(title(for: ingredient))? \(message(for: ingredient))"
    }

    static func message(for _: Ingredient) -> String {
        "This removes the unused ingredient record. No recipe ingredient rows will be removed."
    }

    static func inUseMessage(for ingredient: Ingredient) -> String {
        let recipeCount = (ingredient.recipes ?? []).count
        let recipeLabel = recipeCount == 1 ? "recipe" : "recipes"

        return "Delete is available only when no recipes use this ingredient. " +
            "\(ingredient.value) is still used by \(recipeCount) \(recipeLabel)."
    }

    static func rejectionDialog(for ingredient: Ingredient) -> String {
        "Cannot delete \(ingredient.value). " + inUseMessage(for: ingredient)
    }

    static func successDialog(for ingredient: Ingredient) -> String {
        "Deleted \(ingredient.value)"
    }
}
