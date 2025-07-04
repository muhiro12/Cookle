//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
nonisolated final class Recipe {
    private(set) var name = String.empty
    @Relationship
    private(set) var photos = [Photo]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    private(set) var photoObjects = [PhotoObject]?.some(.empty)
    private(set) var servingSize = Int.zero
    private(set) var cookingTime = Int.zero
    @Relationship
    private(set) var ingredients = [Ingredient]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    private(set) var steps = [String].empty
    @Relationship
    private(set) var categories = [Category]?.some(.empty)
    private(set) var note = String.empty

    @Relationship(inverse: \Diary.recipes)
    private(set) var diaries = [Diary]?.some(.empty)
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    private(set) var diaryObjects = [DiaryObject]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext,
                       name: String,
                       photos: [PhotoObject],
                       servingSize: Int,
                       cookingTime: Int,
                       ingredients: [IngredientObject],
                       steps: [String],
                       categories: [Category],
                       note: String) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.name = name
        recipe.photos = photos.compactMap(\.photo)
        recipe.photoObjects = photos
        recipe.servingSize = servingSize
        recipe.cookingTime = cookingTime
        recipe.ingredients = ingredients.compactMap(\.ingredient)
        recipe.ingredientObjects = ingredients
        recipe.steps = steps
        recipe.categories = categories
        recipe.note = note
        return recipe
    }

    func update(name: String,
                photos: [PhotoObject],
                servingSize: Int,
                cookingTime: Int,
                ingredients: [IngredientObject],
                steps: [String],
                categories: [Category],
                note: String) {
        self.name = name
        self.photos = photos.compactMap(\.photo)
        self.photoObjects = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients.compactMap(\.ingredient)
        self.ingredientObjects = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.modifiedTimestamp = .now
    }
}

extension Recipe: Identifiable {}
