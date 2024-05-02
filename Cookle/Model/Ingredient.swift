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
    private(set) var value: String
    private(set) var recipes: [Recipe]

    private init() {
        self.value = ""
        self.recipes = []
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

@Model
final class IngredientObject {
    private(set) var ingredient: Ingredient
    private(set) var amount: String

    private init(ingredient: Ingredient, amount: String) {
        self.ingredient = ingredient
        self.amount = amount
    }

    static func create(context: ModelContext, ingredient: String, amount: String) -> IngredientObject {
        let object = IngredientObject(
            ingredient: .create(context: context, value: ingredient),
            amount: amount
        )
        context.insert(object)
        return object
    }
}
