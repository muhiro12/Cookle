import Foundation

/// Unvalidated recipe form input collected from app or intent surfaces.
public struct RecipeFormInput: Sendable {
    /// Raw recipe name.
    public var name: String
    /// Photos selected or generated for the recipe.
    public var photos: [PhotoData]
    /// Raw serving size text.
    public var servingSize: String
    /// Raw cooking time text.
    public var cookingTime: String
    /// Raw ingredient rows.
    public var ingredients: [RecipeFormIngredientInput]
    /// Raw preparation steps.
    public var steps: [String]
    /// Raw category values.
    public var categories: [String]
    /// Raw recipe note.
    public var note: String

    /// Creates recipe form input from raw row-based values.
    public init(
        name: String,
        photos: [PhotoData],
        servingSize: String,
        cookingTime: String,
        ingredients: [RecipeFormIngredientInput],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }

    /// Creates recipe form input from multiline text fields.
    public init(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredientsText: String,
        stepsText: String,
        categoriesText: String,
        note: String
    ) {
        self.init(
            name: name,
            photos: [],
            servingSize: servingSize == .zero ? "" : servingSize.description,
            cookingTime: cookingTime == .zero ? "" : cookingTime.description,
            ingredients: Self.ingredientInputs(from: ingredientsText),
            steps: Self.lines(from: stepsText),
            categories: Self.lines(from: categoriesText),
            note: note
        )
    }
}

private extension RecipeFormInput {
    static func lines(
        from text: String
    ) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    static func ingredientInputs(
        from text: String
    ) -> [RecipeFormIngredientInput] {
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
                amount: ""
            )
        }
    }
}
