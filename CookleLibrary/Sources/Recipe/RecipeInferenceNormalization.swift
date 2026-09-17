import Foundation

enum RecipeInferenceNormalization {
    private struct NormalizedIngredient {
        let ingredient: RecipeInferenceIngredient
        let group: String?
    }

    static func applying(to inference: RecipeInferenceResult) -> RecipeInferenceResult {
        var groups = [(name: String, ingredients: [String])]()
        let ingredients = inference.ingredients.compactMap { ingredient -> RecipeInferenceIngredient? in
            let normalized = normalize(ingredient)
            guard normalized.ingredient.ingredient.isEmpty == false else {
                return nil
            }
            if let group = normalized.group {
                append(
                    normalized.ingredient.ingredient,
                    to: group,
                    in: &groups
                )
            }
            return normalized.ingredient
        }

        var result = inference
        result.ingredients = ingredients
        result.categories = inference.categories.filter { category in
            isIngredientGroupMarker(category) == false
        }
        let groupNotes = groups.map { group in
            "\(group.name): \(group.ingredients.joined(separator: ", "))"
        }
        let missingGroupNotes = groupNotes.filter { groupNote in
            result.note.contains(groupNote) == false
        }
        if missingGroupNotes.isEmpty == false {
            result.note = [result.note, missingGroupNotes.joined(separator: "\n")]
                .filter { value in
                    value.isEmpty == false
                }
                .joined(separator: "\n\n")
        }
        return result
    }

    static func amountWithoutPreparationQualifier(_ amount: String) -> String {
        let pattern = #/^(.*?)(?:\s*[（(][^（）()\n]+[）)])$/#
        guard let match = amount.wholeMatch(of: pattern) else {
            return amount
        }
        return String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension RecipeInferenceNormalization {
    private static func normalize(
        _ ingredient: RecipeInferenceIngredient
    ) -> NormalizedIngredient {
        let groupedIngredient = removingGroupMarker(from: ingredient.ingredient)
        let preparedIngredient = movingPreparationQualifier(
            from: groupedIngredient.ingredient,
            to: ingredient.amount
        )
        return .init(
            ingredient: preparedIngredient,
            group: groupedIngredient.group
        )
    }

    static func removingGroupMarker(
        from ingredient: String
    ) -> (ingredient: String, group: String?) {
        let bracketedPattern = #/^[\[［【(（]\s*([A-ZＡ-Ｚ])\s*[\]］】)）]\s*(.+)$/#
        if let match = ingredient.wholeMatch(of: bracketedPattern) {
            return (
                String(match.2).trimmingCharacters(in: .whitespacesAndNewlines),
                normalizedGroupName(String(match.1))
            )
        }

        let plainPattern = #/^([A-ZＡ-Ｚ])(?:[\s:：.．、)）\]】]+)(.+)$/#
        if let match = ingredient.wholeMatch(of: plainPattern) {
            return (
                String(match.2).trimmingCharacters(in: .whitespacesAndNewlines),
                normalizedGroupName(String(match.1))
            )
        }

        return (ingredient, nil)
    }

    static func isIngredientGroupMarker(_ category: String) -> Bool {
        let barePattern = #/^[A-ZＡ-Ｚ]$/#
        let bracketedPattern = #/^[\[［【(（]\s*[A-ZＡ-Ｚ]\s*[\]］】)）]$/#
        return category.wholeMatch(of: barePattern) != nil
            || category.wholeMatch(of: bracketedPattern) != nil
    }

    static func normalizedGroupName(_ group: String) -> String {
        group.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? group
    }

    static func movingPreparationQualifier(
        from ingredient: String,
        to amount: String
    ) -> RecipeInferenceIngredient {
        let pattern = #/^(.*?)(\s*[（(][^（）()\n]+[）)])$/#
        guard let match = ingredient.wholeMatch(of: pattern) else {
            return .init(ingredient: ingredient, amount: amount)
        }
        let baseIngredient = String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
        guard baseIngredient.isEmpty == false else {
            return .init(ingredient: ingredient, amount: amount)
        }
        let qualifier = String(match.2).trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount: String
        if amount.isEmpty {
            normalizedAmount = qualifier
        } else if amount.contains(qualifier) {
            normalizedAmount = amount
        } else {
            normalizedAmount = "\(amount)\(qualifier)"
        }
        return .init(
            ingredient: baseIngredient,
            amount: normalizedAmount
        )
    }

    static func append(
        _ ingredient: String,
        to group: String,
        in groups: inout [(name: String, ingredients: [String])]
    ) {
        if let index = groups.firstIndex(where: { value in
            value.name == group
        }) {
            if groups[index].ingredients.contains(ingredient) == false {
                groups[index].ingredients.append(ingredient)
            }
        } else {
            groups.append((group, [ingredient]))
        }
    }
}
