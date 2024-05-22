//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftUI
import SwiftData

@Model
final class Ingredient: Tag {
    private(set) var value: String!
    private(set) var objects: [IngredientObject]!
    @Relationship(inverse: \Recipe.ingredients)
    private(set) var recipes: [Recipe]!

    private init() {
        self.value = ""
        self.recipes = []
        self.objects = []
    }

    static func create(context: ModelContext, value: String) -> Self {
        let ingredient: Ingredient = (try? context.fetch(.init(predicate: #Predicate { $0.value == value })).first) ?? .init()
        context.insert(ingredient)
        ingredient.value = value
        return ingredient as! Self
    }

    func update(value: String) {
        self.value = value
    }
}

extension Ingredient {
    static var descriptor: FetchDescriptor<Ingredient> {
        .init(
            sortBy: [
                .init(\.value)
            ]
        )
    }
}
