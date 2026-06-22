import CookleLibrary

enum CategoryDeleteCopy {
    static func title(for category: Category) -> String {
        "Delete \(category.value)"
    }

    static func confirmationDialog(for category: Category) -> String {
        "\(title(for: category))? \(message(for: category))"
    }

    static func message(for category: Category) -> String {
        let affectedRecipeCount = (category.recipes ?? []).count
        let recipeLabel = affectedRecipeCount == 1 ? "recipe" : "recipes"

        if affectedRecipeCount == 0 {
            return "This removes the category. No recipe relations will be removed."
        }

        return "This removes the category from \(affectedRecipeCount) " +
            "\(recipeLabel). The recipes stay saved."
    }

    static func successDialog(for category: Category) -> String {
        "Deleted \(category.value)"
    }
}
