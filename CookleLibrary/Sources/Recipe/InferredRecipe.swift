//
//  InferredRecipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

/// Best-effort recipe structure inferred from free-form text.
@available(iOS 26.0, *)
@Generable(
    description: "Structured recipe form fields extracted conservatively from recipe-like text."
)
public struct InferredRecipe {
    /// Recipe name.
    @Guide(
        description: "Recipe title exactly as written or clearly implied by the input. Leave empty if unknown."
    )
    public var name: String
    /// Number of servings.
    @Guide(
        description: "Serving count only when explicitly stated. Use 0 if unknown."
    )
    public var servingSize: Int
    /// Cooking time in minutes.
    @Guide(
        description: "Cooking time in minutes only when explicitly stated. Use 0 if unknown."
    )
    public var cookingTime: Int
    /// Ingredient/amount pairs.
    @Guide(
        description: "Ingredient entries explicitly listed in the input. Omit entries that are not stated."
    )
    public var ingredients: [InferredRecipeIngredient]
    /// Cooking steps.
    @Guide(
        description: "Preparation steps in their original order. Keep each step short and avoid adding new steps."
    )
    public var steps: [String]
    /// Category labels.
    @Guide(
        description: "Short recipe categories only when clearly provided in the input. Otherwise return an empty array."
    )
    public var categories: [String]
    /// Free-form note.
    @Guide(
        description: "Extra recipe note text that is explicit in the input and does not belong in ingredients or steps."
    )
    public var note: String

    /// Creates an inferred recipe value.
    public init(
        name: String,
        servingSize: Int,
        cookingTime: Int,
        ingredients: [InferredRecipeIngredient],
        steps: [String],
        categories: [String],
        note: String
    ) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
    }
}
