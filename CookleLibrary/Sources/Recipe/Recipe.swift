//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

/// Persistent recipe entity.
@Model
nonisolated public final class Recipe {
    /// Human-readable recipe name.
    public private(set) var name = String.empty
    @Relationship
    /// Linked photos (flattened).
    public private(set) var photos = [Photo]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    /// Photo objects preserving order/metadata.
    public private(set) var photoObjects = [PhotoObject]?.some(.empty)
    /// Number of servings.
    public private(set) var servingSize = Int.zero
    /// Cooking time in minutes.
    public private(set) var cookingTime = Int.zero
    @Relationship
    /// Linked ingredient tags.
    public private(set) var ingredients = [Ingredient]?.some(.empty)
    @Relationship(deleteRule: .cascade)
    /// Ingredient objects with amount and order.
    public private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    /// Ordered cooking steps.
    public private(set) var steps = [String].empty
    @Relationship
    /// Linked category tags.
    public private(set) var categories = [Category]?.some(.empty)
    /// Optional free-form note.
    public private(set) var note = String.empty

    @Relationship(inverse: \Diary.recipes)
    public private(set) var diaries = [Diary]?.some(.empty)
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    public private(set) var diaryObjects = [DiaryObject]?.some(.empty)

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    /// Creates and inserts a new recipe.
    /// - Parameters:
    ///   - context: Model context to insert into.
    ///   - name: Recipe name.
    ///   - photos: Photo objects in display order.
    ///   - servingSize: Number of servings.
    ///   - cookingTime: Time in minutes.
    ///   - ingredients: Ingredient objects in order.
    ///   - steps: Cooking steps.
    ///   - categories: Category tags.
    ///   - note: Optional note.
    /// - Returns: The newly created `Recipe`.
    // swiftlint:disable:next function_parameter_count
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

    /// Updates the recipe fields and refreshes the modification timestamp.
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
