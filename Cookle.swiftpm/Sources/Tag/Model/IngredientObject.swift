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
    private(set) var order: Int!
    @Relationship
    private(set) var recipe: Recipe?

    private init(ingredient: Ingredient) {
        self.ingredient = ingredient
        self.amount = ""
        self.order = .zero
        self.recipe = nil
    }

    static func create(context: ModelContext, ingredient: String, amount: String, order: Int) -> IngredientObject {
        let object = IngredientObject(
            ingredient: .create(context: context, value: ingredient)
        )
        context.insert(object)
        object.amount = amount
        object.order = order
        return object
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
