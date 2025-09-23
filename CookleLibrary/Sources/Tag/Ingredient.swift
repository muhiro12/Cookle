//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
public nonisolated final class Ingredient: Tag {
    public private(set) var value = String.empty

    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.ingredient)
    public private(set) var objects = [IngredientObject]?.some(.empty)
    @Relationship(inverse: \Recipe.ingredients)
    public private(set) var recipes = [Recipe]?.some(.empty)

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    public static func create(context: ModelContext, value: String) -> Self {
        let ingredient = (try? context.fetchFirst(.ingredients(.valueIs(value)))) ?? .init()
        context.insert(ingredient)
        ingredient.value = value
        return ingredient as! Self
    }

    public func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Ingredient {
    public static var titleKey: String {
        "Ingredients"
    }

    public static func descriptor(_ predicate: TagPredicate<Ingredient>, order: SortOrder) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate, order: order)
    }

    public static func descriptor(_ predicate: TagPredicate<Ingredient>) -> FetchDescriptor<Ingredient> {
        .ingredients(predicate)
    }
}
