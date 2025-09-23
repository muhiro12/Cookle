//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import Foundation
import SwiftData

@Model
public nonisolated final class IngredientObject: SubObject {
    @Relationship
    public private(set) var ingredient = Ingredient?.none
    public private(set) var amount = String.empty
    public private(set) var order = Int.zero

    @Relationship(inverse: \Recipe.ingredientObjects)
    public private(set) var recipe = Recipe?.none

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init(ingredient: Ingredient) {
        self.ingredient = ingredient
    }

    public static func create(context: ModelContext, ingredient: String, amount: String, order: Int) -> IngredientObject {
        let object = IngredientObject(
            ingredient: .create(context: context, value: ingredient)
        )
        context.insert(object)
        object.amount = amount
        object.order = order
        return object
    }
}
