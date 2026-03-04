import Foundation

enum RecipeIntentDraftBuilder {
    static func makeDraft(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredientsText: String,
        stepsText: String,
        categoriesText: String,
        note: String
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: name,
            photos: [],
            servingSize: servingSize == .zero ? .empty : servingSize.description,
            cookingTime: cookingTime == .zero ? .empty : cookingTime.description,
            ingredients: ingredientInputs(from: ingredientsText),
            steps: lines(from: stepsText),
            categories: lines(from: categoriesText),
            note: note
        )
    }
}

private extension RecipeIntentDraftBuilder {
    static func lines(from text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter(\.isNotEmpty)
    }

    static func ingredientInputs(from text: String) -> [RecipeFormIngredientInput] {
        lines(from: text).map { line in
            if let range = line.range(of: ":") {
                let ingredient = String(line[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let amount = String(line[range.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return .init(
                    ingredient: ingredient,
                    amount: amount
                )
            }

            if let range = line.range(of: " - ") {
                let ingredient = String(line[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let amount = String(line[range.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return .init(
                    ingredient: ingredient,
                    amount: amount
                )
            }

            return .init(
                ingredient: line,
                amount: .empty
            )
        }
    }
}
