import Foundation
import SwiftData

/// Recipe form domain service used by app and widgets.
@preconcurrency
@MainActor
public enum RecipeFormService {
    // swiftlint:disable function_parameter_count
    /// Builds a validated draft from raw form input.
    public static func makeDraft(
        name: String,
        photos: [PhotoData],
        servingSize: String,
        cookingTime: String,
        ingredients: [RecipeFormIngredientInput],
        steps: [String],
        categories: [String],
        note: String
    ) throws -> RecipeFormDraft {
        guard name.isNotEmpty else {
            throw RecipeFormValidationError.emptyName
        }
        let servingSizeValue = try number(
            from: servingSize,
            field: .servingSize
        )
        let cookingTimeValue = try number(
            from: cookingTime,
            field: .cookingTime
        )
        let normalizedIngredients = ingredients.filter(\.ingredient.isNotEmpty)

        return .init(
            name: name,
            photos: photos,
            servingSize: servingSizeValue,
            cookingTime: cookingTimeValue,
            ingredients: normalizedIngredients,
            steps: steps.filter(\.isNotEmpty),
            categories: categories.filter(\.isNotEmpty),
            note: note
        )
    }

    /// Builds a validated draft from App Intent style text input.
    public static func makeDraft(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredientsText: String,
        stepsText: String,
        categoriesText: String,
        note: String
    ) throws -> RecipeFormDraft {
        try makeDraft(
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
    // swiftlint:enable function_parameter_count

    /// Creates a new recipe from a validated draft.
    public static func create(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: draft.name,
            photos: zip(
                draft.photos.indices,
                draft.photos
            ).map { index, photoData in
                PhotoObject.create(
                    context: context,
                    photoData: photoData,
                    order: index + 1
                )
            },
            servingSize: draft.servingSize,
            cookingTime: draft.cookingTime,
            ingredients: zip(
                draft.ingredients.indices,
                draft.ingredients
            ).map { index, ingredientInput in
                IngredientObject.create(
                    context: context,
                    ingredient: ingredientInput.ingredient,
                    amount: ingredientInput.amount,
                    order: index + 1
                )
            },
            steps: draft.steps,
            categories: draft.categories.map { categoryValue in
                Category.create(
                    context: context,
                    value: categoryValue
                )
            },
            note: draft.note
        )
    }

    /// Updates an existing recipe from a validated draft.
    public static func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft
    ) {
        recipe.update(
            name: draft.name,
            photos: zip(
                draft.photos.indices,
                draft.photos
            ).map { index, photoData in
                PhotoObject.create(
                    context: context,
                    photoData: photoData,
                    order: index + 1
                )
            },
            servingSize: draft.servingSize,
            cookingTime: draft.cookingTime,
            ingredients: zip(
                draft.ingredients.indices,
                draft.ingredients
            ).map { index, ingredientInput in
                IngredientObject.create(
                    context: context,
                    ingredient: ingredientInput.ingredient,
                    amount: ingredientInput.amount,
                    order: index + 1
                )
            },
            steps: draft.steps,
            categories: draft.categories.map { categoryValue in
                Category.create(
                    context: context,
                    value: categoryValue
                )
            },
            note: draft.note
        )
    }
}

private extension RecipeFormService {
    enum NumberField {
        case servingSize
        case cookingTime
    }

    static func number(
        from value: String,
        field: NumberField
    ) throws -> Int {
        guard value.isNotEmpty else {
            return .zero
        }
        let normalizedValue = value.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? .empty
        guard let number = Int(normalizedValue) else {
            switch field {
            case .servingSize:
                throw RecipeFormValidationError.invalidServingSize(value)
            case .cookingTime:
                throw RecipeFormValidationError.invalidCookingTime(value)
            }
        }
        return number
    }

    static func lines(
        from text: String
    ) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter(\.isNotEmpty)
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
                amount: .empty
            )
        }
    }
}
