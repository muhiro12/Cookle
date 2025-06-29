//
//  InferredRecipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import FoundationModels

@available(iOS 26.0, *)
@Generable
struct InferredRecipe {
    var name: String
    var servingSize: Int
    var cookingTime: Int
    var ingredients: [InferredRecipeIngredient]
    var steps: [String]
    var categories: [String]
    var note: String
}
