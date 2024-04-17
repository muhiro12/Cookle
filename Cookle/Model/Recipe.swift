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
    @Relationship(inverse: \Category.recipes)
    private(set) var categories: [Category]
    private(set) var servingSize: Int
    private(set) var cookingTime: Int
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients: [Ingredient]
    private(set) var steps: [String]
    private(set) var updatedAt: Date
    private(set) var createdAt: Date
    @Relationship(inverse: \Diary.recipes)
    private(set) var diaries: [Diary]

    private init() {
        self.name = ""
        self.categories = []
        self.servingSize = 0
        self.cookingTime = 0
        self.ingredients = []
        self.steps = []
        self.updatedAt = .now
        self.createdAt = .now
        self.diaries = []
    }

    static func create(name: String,
                       categories: [String],
                       servingSize: Int,
                       cookingTime: Int,
                       ingredients: [String],
                       steps: [String]) -> Recipe {
        let recipe = Recipe()
        recipe.name = name
        recipe.categories = categories.map { .init($0) }
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredients = ingredients.map { .init($0) }
        recipe.steps = steps
        return recipe
    }

    func update(name: String,
                categories: [String],
                servingSize: Int,
                cookingTime: Int,
                ingredients: [String],
                steps: [String]) {
        self.name = name
        self.categories = categories.map { .init($0) }
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients.map { .init($0) }
        self.steps = steps
        self.updatedAt = .now
    }
}
