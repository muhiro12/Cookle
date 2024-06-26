//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import Foundation
import SwiftData

@Model
final class IngredientObject {
    @Relationship
    private(set) var ingredient = Ingredient?.none
    private(set) var amount = String.empty
    private(set) var order = Int.zero

    @Relationship(inverse: \Recipe.ingredientObjects)
    private(set) var recipe = Recipe?.none

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init(ingredient: Ingredient) {
        self.ingredient = ingredient
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
                .init(\.modifiedTimestamp, order: .reverse)
            ]
        )
    }
}
