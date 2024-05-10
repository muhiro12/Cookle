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
    private(set) var recipeIngredients: [RecipeIngredient]
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
        self.recipeIngredients = []
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
                       ingredients: [RecipeIngredient],
                       steps: [String],
                       categories: [Category]) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.name = name
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredients = ingredients.map { $0.ingredient }
        recipe.recipeIngredients = ingredients
        recipe.steps = steps
        recipe.categories = categories
        return recipe
    }

    func update(context: ModelContext,
                name: String,
                servingSize: Int,
                cookingTime: Int,
                ingredients: [RecipeIngredient],
                steps: [String],
                categories: [Category]) {
        self.name = name
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients.map { $0.ingredient }
        self.recipeIngredients = ingredients
        self.steps = steps
        self.categories = categories
        self.updatedAt = .now
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
