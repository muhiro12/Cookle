import Foundation

public extension RecipeOperations {
    /// Returns readable recipe content for copying or sharing, without changing the store.
    ///
    /// Preserves ingredient and step order and literal multiline content. Unknown numeric
    /// values and empty sections are omitted. Photos, identity, and cooking history are
    /// excluded; this text is not a versioned import format.
    static func contentText(
        for recipe: Recipe,
        labels: RecipeContentTextLabels
    ) -> String {
        var sections = [recipe.name]
        if recipe.servingSize > .zero {
            sections.append("\(labels.servings): \(recipe.servingSize)")
        }
        if recipe.cookingTime > .zero {
            sections.append("\(labels.cookingTime): \(recipe.cookingTime)")
        }
        let ingredients = recipe.ingredientObjects?.sorted().compactMap { object -> String? in
            guard let ingredient = object.ingredient else {
                return nil
            }
            return object.amount.isEmpty ? "• \(ingredient.value)" : "• \(ingredient.value): \(object.amount)"
        } ?? []
        if !ingredients.isEmpty {
            sections.append(labels.ingredients + "\n" + ingredients.joined(separator: "\n"))
        }
        if !recipe.steps.isEmpty {
            let steps = recipe.steps.enumerated().map { index, step in
                "\(index + 1). \(step)"
            }
            sections.append(labels.steps + "\n" + steps.joined(separator: "\n"))
        }
        let categories = recipe.categories?.map(\.value).sorted() ?? []
        if !categories.isEmpty {
            sections.append(labels.categories + "\n" + categories.joined(separator: ", "))
        }
        if !recipe.note.isEmpty {
            sections.append(labels.note + "\n" + recipe.note)
        }
        return sections.joined(separator: "\n\n")
    }
}
