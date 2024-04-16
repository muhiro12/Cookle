//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
final class Recipe: Identifiable {
    private(set) var name: String
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients: [Ingredient]
    private(set) var instructions: [String]
    @Relationship(inverse: \Category.recipes)
    private(set) var categories: [Category]
    private(set) var diaries: [Diary]
    private(set) var updateDate: Date
    private(set) var creationDate: Date

    private init() {
        self.name = ""
        self.ingredients = []
        self.instructions = []
        self.categories = []
        self.updateDate = .now
        self.creationDate = .now
        self.diaries = []
    }

    static func factory(name: String, ingredients: [String], instructions: [String], categories: [String]) -> Recipe {
        let recipe = Recipe()
        recipe.name = name
        recipe.ingredients = ingredients.map { .init($0) }
        recipe.instructions = instructions
        recipe.categories = categories.map { .init($0) }
        return recipe
    }

    func set(name: String, ingredients: [String], instructions: [String], categories: [String]) {
        self.name = .init(name)
        self.ingredients = ingredients.map { .init($0) }
        self.instructions = instructions.map { .init($0) }
        self.categories = categories.map { .init($0) }
    }
}
