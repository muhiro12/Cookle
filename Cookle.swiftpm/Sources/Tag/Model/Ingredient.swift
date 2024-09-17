//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData
import SwiftUI

@Model
final class Ingredient: Tag {
    private(set) var value = String.empty

    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.ingredient)
    private(set) var objects = [IngredientObject]?.some(.empty)
    @Relationship(inverse: \Recipe.ingredients)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext, value: String) -> Self {
        let ingredient: Ingredient = (try? context.fetch(.init(predicate: #Predicate { $0.value == value })).first) ?? .init()
        context.insert(ingredient)
        ingredient.value = value
        return ingredient as! Self
    }

    func update(value: String) {
        self.value = value
        self.modifiedTimestamp = .now
    }
}

extension Ingredient {
    static var title: LocalizedStringKey {
        "Ingredients"
    }

    static var descriptor: FetchDescriptor<Ingredient> {
        .ingredients()
    }
}

extension FetchDescriptor where T == Ingredient {
    static func ingredients(order: SortOrder = .forward) -> FetchDescriptor {
        .init(
            sortBy: [
                .init(\.value, order: order)
            ]
        )
    }
}
