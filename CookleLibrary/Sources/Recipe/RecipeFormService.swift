import Foundation
import SwiftData

/// Internal recipe form collaborator used by public Operations.
@preconcurrency
@MainActor
enum RecipeFormService {
    /// Builds a validated draft from raw form input.
    static func makeDraft(
        input: RecipeFormInput
    ) throws -> RecipeFormDraft {
        guard !input.name.isEmpty else {
            throw RecipeFormValidationError.emptyName
        }
        let servingSizeValue = try number(
            from: input.servingSize,
            field: .servingSize
        )
        let cookingTimeValue = try number(
            from: input.cookingTime,
            field: .cookingTime
        )
        let normalizedIngredients = input.ingredients.filter { ingredient in
            !ingredient.ingredient.isEmpty
        }

        return .init(
            name: input.name,
            photos: input.photos,
            servingSize: servingSizeValue,
            cookingTime: cookingTimeValue,
            ingredients: normalizedIngredients,
            steps: input.steps.filter { !$0.isEmpty },
            categories: input.categories.filter { !$0.isEmpty },
            note: input.note
        )
    }

    /// Creates a new recipe from a validated draft.
    static func create(
        context: ModelContext,
        draft: RecipeFormDraft
    ) throws -> Recipe {
        try createWithOutcome(
            context: context,
            draft: draft
        ).value
    }

    /// Creates a new recipe from a validated draft and returns follow-up hints.
    static func createWithOutcome(
        context: ModelContext,
        draft: RecipeFormDraft
    ) throws -> MutationOutcome<Recipe> {
        let recipe = Recipe.create(
            context: context,
            content: try recipeContent(
                from: draft,
                context: context
            )
        )
        return .init(
            value: recipe,
            effects: recipeMutationEffects
        )
    }

    /// Updates an existing recipe from a validated draft.
    static func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft
    ) throws {
        _ = try updateWithOutcome(
            context: context,
            recipe: recipe,
            draft: draft
        )
    }

    /// Updates an existing recipe from a validated draft and returns follow-up hints.
    static func updateWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft
    ) throws -> MutationOutcome<Recipe> {
        let previousPhotoObjects = (recipe.photoObjects ?? [])
        let previousIngredientObjects = (recipe.ingredientObjects ?? [])
        let updatedPhotoObjects = try zip(
            draft.photos.indices,
            draft.photos
        ).map { index, photoData in
            try PhotoObject.create(
                context: context,
                photoData: photoData,
                order: index + 1
            )
        }
        let updatedIngredientObjects = try zip(
            draft.ingredients.indices,
            draft.ingredients
        ).map { index, ingredientInput in
            try IngredientObject.create(
                context: context,
                ingredient: ingredientInput.ingredient,
                amount: ingredientInput.amount,
                order: index + 1
            )
        }

        recipe.update(
            content: .init(
                name: draft.name,
                photos: updatedPhotoObjects,
                servingSize: draft.servingSize,
                cookingTime: draft.cookingTime,
                ingredients: updatedIngredientObjects,
                steps: draft.steps,
                categories: try categories(
                    from: draft,
                    context: context
                ),
                note: draft.note
            )
        )
        previousPhotoObjects.forEach(context.delete)
        previousIngredientObjects.forEach(context.delete)
        return .init(
            value: recipe,
            effects: recipeMutationEffects
        )
    }
}

private extension RecipeFormService {
    enum NumberField {
        case servingSize
        case cookingTime
    }

    static var recipeMutationEffects: MutationEffect {
        [
            .recipeDataChanged,
            .notificationPlanChanged
        ]
    }

    static func number(
        from value: String,
        field: NumberField
    ) throws -> Int {
        guard !value.isEmpty else {
            return .zero
        }
        let normalizedValue = value.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? ""
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

    static func recipeContent(
        from draft: RecipeFormDraft,
        context: ModelContext
    ) throws -> RecipeContent {
        .init(
            name: draft.name,
            photos: try photoObjects(
                from: draft,
                context: context
            ),
            servingSize: draft.servingSize,
            cookingTime: draft.cookingTime,
            ingredients: try ingredientObjects(
                from: draft,
                context: context
            ),
            steps: draft.steps,
            categories: try categories(
                from: draft,
                context: context
            ),
            note: draft.note
        )
    }

    static func photoObjects(
        from draft: RecipeFormDraft,
        context: ModelContext
    ) throws -> [PhotoObject] {
        try zip(
            draft.photos.indices,
            draft.photos
        ).map { index, photoData in
            try PhotoObject.create(
                context: context,
                photoData: photoData,
                order: index + 1
            )
        }
    }

    static func ingredientObjects(
        from draft: RecipeFormDraft,
        context: ModelContext
    ) throws -> [IngredientObject] {
        try zip(
            draft.ingredients.indices,
            draft.ingredients
        ).map { index, ingredientInput in
            try IngredientObject.create(
                context: context,
                ingredient: ingredientInput.ingredient,
                amount: ingredientInput.amount,
                order: index + 1
            )
        }
    }

    static func categories(
        from draft: RecipeFormDraft,
        context: ModelContext
    ) throws -> [Category] {
        try draft.categories.map { categoryValue in
            try Category.create(
                context: context,
                value: categoryValue
            )
        }
    }
}
