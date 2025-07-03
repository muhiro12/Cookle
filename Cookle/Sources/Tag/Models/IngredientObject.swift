//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import Foundation
import SwiftData

@Model
final class IngredientObject: SubObject {
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

    @MainActor
    static func create(container: ModelContainer, ingredient: String, amount: String, order: Int) -> IngredientObject {
        let object = IngredientObject(
            ingredient: .create(container: container, value: ingredient)
        )
        container.mainContext.insert(object)
        object.amount = amount
        object.order = order
        return object
    }
}
