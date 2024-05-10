//
//  RecipeIngredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import SwiftData

@Model
final class RecipeIngredient {
    private(set) var ingredient: Ingredient
    private(set) var amount: String

    private init(ingredient: Ingredient, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }

    static func create(context: ModelContext, ingredient: String, amount: String) -> RecipeIngredient {
        let recipeIngredient = RecipeIngredient(
            ingredient: .create(context: context, value: ingredient),
            amount: amount
        )
        context.insert(recipeIngredient)
        return recipeIngredient
    }
}
