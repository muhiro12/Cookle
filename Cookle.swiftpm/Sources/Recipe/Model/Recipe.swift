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
    private(set) var name: String!
    private(set) var servingSize: Int!
    private(set) var cookingTime: Int!
    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.recipe)
    private(set) var ingredientObjects: [IngredientObject]!
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients: [Ingredient]!
    private(set) var steps: [String]!
    @Relationship(inverse: \Category.recipes)
    private(set) var categories: [Category]!
    @Relationship(inverse: \Diary.breakfasts)
    private(set) var breakfasts: [Diary]!
    @Relationship(inverse: \Diary.lunches)
    private(set) var lunches: [Diary]!
    @Relationship(inverse: \Diary.dinners)
    private(set) var dinners: [Diary]!
    private(set) var updatedAt: Date!
    private(set) var createdAt: Date!

    private init() {
        self.name = ""
        self.servingSize = 0
        self.cookingTime = 0
        self.ingredientObjects = []
        self.ingredients = []
        self.steps = []
        self.categories = []
        self.breakfasts = []
        self.lunches = []
        self.dinners = []
        self.updatedAt = .now
        self.createdAt = .now
    }

    static func create(context: ModelContext,
                       name: String,
                       servingSize: Int,
                       cookingTime: Int,
                       ingredients: [IngredientObject],
                       steps: [String],
                       categories: [Category]) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.name = name
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredientObjects = ingredients
        recipe.ingredients = ingredients.map { $0.ingredient }
        recipe.steps = steps
        recipe.categories = categories
        return recipe
    }

    func update(name: String,
                servingSize: Int,
                cookingTime: Int,
                ingredients: [IngredientObject],
                steps: [String],
                categories: [Category]) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredientObjects = ingredients
        self.ingredients = ingredients.map { $0.ingredient }
        self.steps = steps
        self.categories = categories
        self.updatedAt = .now
    }
    
    func delete() {
        modelContext?.delete(self)
    }
}

extension Recipe {
    static var descriptor: FetchDescriptor<Recipe> {
        .init(
            sortBy: [
                .init(\.name)
            ]
        )
    }
}
