//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

/// Ingredient tag model.
@Model
public nonisolated final class Ingredient: Tag {
    /// Ingredient display value.
    public private(set) var value = String.empty

    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.ingredient)
    /// Ingredient objects that carry amounts and order.
    public private(set) var objects = [IngredientObject]?.some(.empty)
    @Relationship(inverse: \Recipe.ingredients)
    /// Recipes linked to this ingredient.
    public private(set) var recipes = [Recipe]?.some(.empty)

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    /// Creates (or returns) an ingredient with the given value.
    public static func create(context: ModelContext, value: String) -> Self {
        let ingredient = (try? context.fetchFirst(.ingredients(.valueIs(value)))) ?? .init()
        context.insert(ingredient)
        ingredient.value = value
        return ingredient as! Self
    }

    /// Updates the ingredient value.
    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Ingredient {
    /// Localizable title key used in UI.
    public static var titleKey: String {
        "Ingredients"
    }

    /// Convenience descriptor with explicit order.
    public static func descriptor(_ predicate: TagPredicate<Ingredient>, order: SortOrder) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate, order: order)
    }

    /// Convenience descriptor with default order.
    public static func descriptor(_ predicate: TagPredicate<Ingredient>) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate)
    }
}
