//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    private(set) var name: String!
    private(set) var photos: [Data]!
    private(set) var servingSize: Int!
    private(set) var cookingTime: Int!
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients: [Ingredient]!
    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.recipe)
    private(set) var ingredientObjects: [IngredientObject]!
    private(set) var steps: [String]!
    @Relationship(inverse: \Category.recipes)
    private(set) var categories: [Category]!
    private(set) var note: String!
    @Relationship
    private(set) var diaries: [Diary]!
    @Relationship(deleteRule: .cascade)
    private(set) var diaryObjects: [DiaryObject]!
    private(set) var createdTimestamp: Date!
    private(set) var modifiedTimestamp: Date!

    private init() {
        self.name = ""
        self.photos = []
        self.servingSize = 0
        self.cookingTime = 0
        self.ingredients = []
        self.ingredientObjects = []
        self.steps = []
        self.categories = []
        self.note = ""
        self.diaries = []
        self.diaryObjects = []
        self.createdTimestamp = .now
        self.modifiedTimestamp = .now
    }

    static func create(context: ModelContext,
                       name: String,
                       photos: [Data],
                       servingSize: Int,
                       cookingTime: Int,
                       ingredients: [IngredientObject],
                       steps: [String],
                       categories: [Category],
                       note: String) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.name = name
        recipe.photos = photos
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredients = ingredients.map { $0.ingredient }
        recipe.ingredientObjects = ingredients
        recipe.steps = steps
        recipe.categories = categories
        recipe.note = note
        return recipe
    }

    func update(name: String,
                photos: [Data],
                servingSize: Int,
                cookingTime: Int,
                ingredients: [IngredientObject],
                steps: [String],
                categories: [Category],
                note: String) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients.map { $0.ingredient }
        self.ingredientObjects = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.modifiedTimestamp = .now
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
