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
    private(set) var name = String.empty
    @Relationship(inverse: \Photo.recipes)
    private(set) var photos = [Photo]?.some(.empty)
    private(set) var servingSize = Int.zero
    private(set) var cookingTime = Int.zero
    @Relationship(inverse: \Ingredient.recipes)
    private(set) var ingredients = [Ingredient]?.some(.empty)
    @Relationship(deleteRule: .cascade, inverse: \IngredientObject.recipe)
    private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    private(set) var steps = [String].empty
    @Relationship(inverse: \Category.recipes)
    private(set) var categories = [Category]?.some(.empty)
    private(set) var note = String.empty
    @Relationship
    private(set) var diaries = [Diary]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    private(set) var diaryObjects = [DiaryObject]?.some(.empty)
    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext,
                       name: String,
                       photos: [Photo],
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
        recipe.ingredients = ingredients.compactMap { $0.ingredient }
        recipe.ingredientObjects = ingredients
        recipe.steps = steps
        recipe.categories = categories
        recipe.note = note
        return recipe
    }

    func update(name: String,
                photos: [Photo],
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
        self.ingredients = ingredients.compactMap { $0.ingredient }
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
