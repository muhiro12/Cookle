//
//  InferredRecipeIngredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

@available(iOS 26.0, *)
@Generable
public struct InferredRecipeIngredient {
    public var ingredient: String
    public var amount: String

    public init(ingredient: String, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }
}
