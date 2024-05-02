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
    private(set) var servingSize: Int
    private(set) var cookingTime: Int
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients: [Ingredient]
    private(set) var steps: [String]
    @Relationship(inverse: \Category.recipes)
    private(set) var categories: [Category]
    @Relationship(inverse: \Diary.recipes)
    private(set) var diaries: [Diary]
    private(set) var updatedAt: Date
    private(set) var createdAt: Date

    private init() {
        self.name = ""
        self.servingSize = 0
        self.cookingTime = 0
        self.ingredients = []
        self.steps = []
        self.categories = []
        self.diaries = []
        self.updatedAt = .now
        self.createdAt = .now
    }

    static func create(context: ModelContext,
                       name: String,
                       servingSize: Int,
                       cookingTime: Int,
                       ingredients: [String],
                       steps: [String],
                       categories: [String]) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.name = name
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredients = Set(ingredients).map { .create(context: context, value: $0) }
        recipe.steps = steps
        recipe.categories = Set(categories).map { .create(context: context, value: $0) }
        return recipe
    }

    func update(context: ModelContext,
                name: String,
                servingSize: Int,
                cookingTime: Int,
                ingredients: [String],
                steps: [String],
                categories: [String]) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = Set(ingredients).map { .create(context: context, value: $0) }
        self.steps = steps
        self.categories = Set(categories).map { .create(context: context, value: $0) }
        self.updatedAt = .now
    }
}
