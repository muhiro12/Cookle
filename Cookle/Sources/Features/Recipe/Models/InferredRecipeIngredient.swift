//
//  InferredRecipeIngredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

/// Ingredient/amount pair inferred from text.
@available(iOS 26.0, *)
@Generable(
    description: "A single ingredient entry extracted from recipe-like text."
)
public struct InferredRecipeIngredient {
    /// Ingredient name.
    @Guide(
        description: "Ingredient name exactly as written in the input. Omit the entry if no ingredient is explicit."
    )
    public var ingredient: String
    /// Human-readable amount.
    @Guide(
        description: "Amount or measurement written next to the ingredient. Use an empty string if missing."
    )
    public var amount: String

    var recipeInferenceIngredient: RecipeInferenceIngredient {
        .init(
            ingredient: ingredient,
            amount: amount
        )
    }

    /// Creates an inferred ingredient entry.
    public init(ingredient: String, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }
}
