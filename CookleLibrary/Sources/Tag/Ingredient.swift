//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData
import SwiftUI

/// Persisted ingredient tag reused across recipe forms, search, and filtering.
@Model
nonisolated public final class Ingredient: Tag {
    /// Canonical ingredient label shown in recipe forms and search results.
    public private(set) var value = String.empty

    /// Recipe rows that attach amounts and ordering metadata to this ingredient.
    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.ingredient)
    public private(set) var objects = [IngredientObject]?.some(.empty)

    /// Recipes that currently reference this ingredient.
    @Relationship(inverse: \Recipe.ingredients)
    public private(set) var recipes = [Recipe]?.some(.empty)

    /// Timestamp captured when the ingredient is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever the ingredient label changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Returns an existing ingredient for `value`, or inserts a new one when needed.
    public static func create(context: ModelContext, value: String) -> Self {
        if let existingIngredient = try? context.fetchFirst(.ingredients(.valueIs(value))),
           let ingredient = existingIngredient as? Self {
            return ingredient
        }

        let ingredient: Self = .init()
        context.insert(ingredient)
        ingredient.value = value
        return ingredient
    }

    /// Replaces the stored ingredient label and refreshes `modifiedTimestamp`.
    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

public extension Ingredient {
    /// Localized section title shown anywhere ingredient collections are presented.
    static var title: LocalizedStringKey {
        "Ingredients"
    }

    /// Builds an ingredient fetch descriptor with an explicit sort order.
    static func descriptor(
        _ predicate: TagPredicate<Ingredient>,
        order: SortOrder
    ) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate, order: order)
    }

    /// Builds an ingredient fetch descriptor using the default sort order.
    static func descriptor(
        _ predicate: TagPredicate<Ingredient>
    ) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate)
    }
}
