//
//  IngredientObject.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/08.
//

import Foundation
import SwiftData

/// Persisted ingredient row that keeps a recipe's chosen tag, amount text, and order.
@Model
nonisolated public final class IngredientObject: SubObject {
    /// Ingredient tag referenced by this row.
    @Relationship public private(set) var ingredient = Ingredient?.none
    /// Free-form amount text shown beside the ingredient label.
    public private(set) var amount = String.empty
    /// Position of this row within the recipe's ingredient list.
    public private(set) var order = Int.zero

    /// Recipe that owns this ingredient row.
    @Relationship(inverse: \Recipe.ingredientObjects)
    public private(set) var recipe = Recipe?.none

    /// Timestamp captured when the row is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp initialized with the row for recency-based queries.
    public private(set) var modifiedTimestamp = Date.now

    private init(ingredient: Ingredient) {
        self.ingredient = ingredient
    }

    /// Inserts an ingredient row and reuses or creates the referenced ingredient tag.
    public static func create(
        context: ModelContext,
        ingredient: String,
        amount: String,
        order: Int
    ) -> IngredientObject {
        let object = IngredientObject(
            ingredient: .create(context: context, value: ingredient)
        )
        context.insert(object)
        object.amount = amount
        object.order = order
        return object
    }
}
