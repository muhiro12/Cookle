//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import Foundation
import SwiftData

/// Ingredient item with amount and order, linked to a recipe.
@Model
nonisolated public final class IngredientObject: SubObject {
    /// Linked ingredient tag.
    @Relationship public private(set) var ingredient = Ingredient?.none
    /// Human-readable amount (e.g. "2", "200g").
    public private(set) var amount = String.empty
    /// Display order within the list.
    public private(set) var order = Int.zero

    /// Owning recipe (inverse relation).
    @Relationship(inverse: \Recipe.ingredientObjects)
    public private(set) var recipe = Recipe?.none

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init(ingredient: Ingredient) {
        self.ingredient = ingredient
    }

    /// Creates and inserts a new ingredient object for the given value.
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
