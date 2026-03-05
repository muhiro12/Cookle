import Foundation

enum RecipeIntentDraftBuilder {
    struct Input {
        let name: String
        let servingSize: Int
        let cookingTime: Int
        let ingredientsText: String
        let stepsText: String
        let categoriesText: String
        let note: String
    }

    static func makeDraft(
        input: Input
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: input.name,
            photos: [],
            servingSize: input.servingSize == .zero ? .empty : input.servingSize.description,
            cookingTime: input.cookingTime == .zero ? .empty : input.cookingTime.description,
            ingredients: ingredientInputs(from: input.ingredientsText),
            steps: lines(from: input.stepsText),
            categories: lines(from: input.categoriesText),
            note: input.note
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
