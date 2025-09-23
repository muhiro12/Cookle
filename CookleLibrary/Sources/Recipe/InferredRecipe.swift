//
//  InferredRecipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

@available(iOS 26.0, *)
@Generable
public struct InferredRecipe {
    public var name: String
    public var servingSize: Int
    public var cookingTime: Int
    public var ingredients: [InferredRecipeIngredient]
    public var steps: [String]
    public var categories: [String]
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
