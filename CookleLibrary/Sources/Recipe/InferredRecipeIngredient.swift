//
//  InferredRecipeIngredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

/// Ingredient/amount pair inferred from text.
@available(iOS 26.0, *)
@Generable
public struct InferredRecipeIngredient {
    /// Ingredient name.
    public var ingredient: String
    /// Human-readable amount.
    public var amount: String

    public init(ingredient: String, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }
}
