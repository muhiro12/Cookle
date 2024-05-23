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
    private(set) var recipe: Recipe?

    private init() {}

    static func create(context: ModelContext, ingredient: String, amount: String) -> IngredientObject {
        let object = IngredientObject()
        context.insert(object)

        object.ingredient = .create(context: context, value: ingredient)
        object.amount = amount
        object.recipe = nil

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
