//
//  InferredRecipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

/// Best-effort recipe structure inferred from free-form text.
@available(iOS 26.0, *)
@Generable
public struct InferredRecipe {
    /// Recipe name.
    public var name: String
    /// Number of servings.
    public var servingSize: Int
    /// Cooking time in minutes.
    public var cookingTime: Int
    /// Ingredient/amount pairs.
    public var ingredients: [InferredRecipeIngredient]
    /// Cooking steps.
    public var steps: [String]
    /// Category labels.
    public var categories: [String]
    /// Free-form note.
    public var note: String

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
