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
    /// Linked photos (flattened).
    @Relationship public private(set) var photos = [Photo]?.some(.empty)
    /// Photo objects preserving order/metadata.
    @Relationship(deleteRule: .cascade)
    public private(set) var photoObjects = [PhotoObject]?.some(.empty)
    /// Number of servings.
    public private(set) var servingSize = Int.zero
    /// Cooking time in minutes.
    public private(set) var cookingTime = Int.zero
    /// Linked ingredient tags.
    @Relationship public private(set) var ingredients = [Ingredient]?.some(.empty)
    /// Ingredient objects with amount and order.
    @Relationship(deleteRule: .cascade)
    public private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    /// Ordered cooking steps.
    public private(set) var steps = [String].empty
    /// Linked category tags.
    @Relationship public private(set) var categories = [Category]?.some(.empty)
    /// Optional free-form note.
    public private(set) var note = String.empty

    /// Diaries referencing this recipe.
    @Relationship(inverse: \Diary.recipes)
    public private(set) var diaries = [Diary]?.some(.empty)
    /// Diary objects referencing this recipe.
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    public private(set) var diaryObjects = [DiaryObject]?.some(.empty)

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    // swiftlint:disable function_parameter_count
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
    // swiftlint:enable function_parameter_count

    // swiftlint:disable function_parameter_count
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
    // swiftlint:enable function_parameter_count
}

extension Recipe: Identifiable {}
