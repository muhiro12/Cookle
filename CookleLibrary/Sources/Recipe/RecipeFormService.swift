import Foundation
import SwiftData

/// Recipe form domain service used by app and widgets.
@MainActor
public enum RecipeFormService {
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
}
