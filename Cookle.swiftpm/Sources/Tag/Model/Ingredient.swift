//
//  Ingredient.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
final class Ingredient: Tag {
    private(set) var value: String!
    @Relationship(deleteRule: .cascade)
    private(set) var objects: [IngredientObject]!
    @Relationship
    private(set) var recipes: [Recipe]!
    private(set) var createdTimestamp: Date!
    private(set) var modifiedTimestamp: Date!

    private init() {
        self.value = ""
        self.recipes = []
        self.objects = []
        self.createdTimestamp = .now
        self.modifiedTimestamp = .now
    }

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
    static var descriptor: FetchDescriptor<Ingredient> {
        .init(
            sortBy: [
                .init(\.value)
            ]
        )
    }
}
