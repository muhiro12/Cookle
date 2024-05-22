//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import SwiftData

@Model
final class IngredientObject {
    @Relationship(inverse: \Ingredient.objects)
    private(set) var ingredient: Ingredient!
    private(set) var amount: String!
    @Relationship(deleteRule: .cascade, inverse: \Recipe.ingredientObjects)
    private(set) var recipe: Recipe?

    private init(ingredient: Ingredient, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
        self.recipe = nil
    }

    static func create(context: ModelContext, ingredient: String, amount: String) -> IngredientObject {
        let ingredientObject = IngredientObject(
            ingredient: .create(context: context, value: ingredient),
            amount: amount
        )
        context.insert(ingredientObject)
        return ingredientObject
    }
}

extension IngredientObject {
    static var descriptor: FetchDescriptor<IngredientObject> {
        .init(
            sortBy: [
                .init(\.ingredient.value)
            ]
        )
    }
}
