enum RecipeDeleteCopy {
    static func title(for recipe: Recipe) -> String {
        String(localized: "Delete \(recipe.name)")
    }

    static func confirmationDialog(for recipe: Recipe) -> String {
        "\(title(for: recipe))? \(message(for: recipe))"
    }

    static func message(for recipe: Recipe) -> String {
        let affectedMealRowCount = (recipe.diaryObjects ?? []).count
        if affectedMealRowCount == 0 {
            return String(
                localized: "This removes the recipe. No diary meal rows will be removed."
            )
        }

        if affectedMealRowCount == 1 {
            return String(
                localized: "This removes the recipe and one diary meal row. The related diary entry stays saved."
            )
        }

        return String(
            localized: """
            This removes the recipe and \(affectedMealRowCount) diary meal rows. \
            The related diary entries stay saved.
            """
        )
    }

    static func successDialog(for recipe: Recipe) -> String {
        String(localized: "Deleted \(recipe.name)")
    }
}
