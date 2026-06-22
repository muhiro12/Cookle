import Foundation

enum RecipeFormPlaceholderRows {
    static func normalizedStrings(
        _ values: [String]
    ) -> [String] {
        normalize(values, isPlaceholder: \.isEmpty) {
            ""
        }
    }

    static func normalizedIngredients(
        _ values: [RecipeFormIngredientInput]
    ) -> [RecipeFormIngredientInput] {
        normalize(
            values,
            isPlaceholder: { ingredient in
                ingredient.ingredient.isEmpty && ingredient.amount.isEmpty
            },
            makePlaceholder: {
                .init(
                    ingredient: "",
                    amount: ""
                )
            }
        )
    }
}

private extension RecipeFormPlaceholderRows {
    static func normalize<Element>(
        _ values: [Element],
        isPlaceholder: (Element) -> Bool,
        makePlaceholder: () -> Element
    ) -> [Element] {
        guard !values.isEmpty else {
            return [makePlaceholder()]
        }

        var normalized = values

        while normalized.count > 1,
              let last = normalized.last,
              let previous = normalized.dropLast().last,
              isPlaceholder(last),
              isPlaceholder(previous) {
            normalized.removeLast()
        }

        if let last = normalized.last,
           isPlaceholder(last) == false {
            normalized.append(makePlaceholder())
        }

        return normalized
    }
}
