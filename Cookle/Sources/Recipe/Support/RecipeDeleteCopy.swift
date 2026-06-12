enum RecipeDeleteCopy {
    static func title(for recipe: Recipe) -> String {
        "Delete \(recipe.name)"
    }

    static func confirmationDialog(for recipe: Recipe) -> String {
        "\(title(for: recipe))? \(message(for: recipe))"
    }

    static func message(for recipe: Recipe) -> String {
        let affectedMealRowCount = (recipe.diaryObjects ?? []).count
        let mealRowLabel = affectedMealRowCount == 1 ? "meal row" : "meal rows"

        if affectedMealRowCount == 0 {
            return "This removes the recipe. No diary meal rows will be removed."
        }

        return "This removes the recipe and \(affectedMealRowCount) diary " +
            "\(mealRowLabel). The related diary entries stay saved."
    }

    static func successDialog(for recipe: Recipe) -> String {
        "Deleted \(recipe.name)"
    }
}
