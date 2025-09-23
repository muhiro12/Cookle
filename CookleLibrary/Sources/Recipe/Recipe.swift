//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
public nonisolated final class Recipe {
    public private(set) var name = String.empty
    @Relationship
    public private(set) var photos = [Photo]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    public private(set) var photoObjects = [PhotoObject]?.some(.empty)
    public private(set) var servingSize = Int.zero
    public private(set) var cookingTime = Int.zero
    @Relationship
    public private(set) var ingredients = [Ingredient]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    public private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    public private(set) var steps = [String].empty
    @Relationship
    public private(set) var categories = [Category]?.some(.empty)
    public private(set) var note = String.empty

    @Relationship(inverse: \Diary.recipes)
    public private(set) var diaries = [Diary]?.some(.empty)
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    public private(set) var diaryObjects = [DiaryObject]?.some(.empty)

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    public static func create(context: ModelContext,
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

    public func update(name: String,
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
