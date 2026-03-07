//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

/// Persisted recipe aggregate with ordered child rows and diary backlinks.
@Model
nonisolated public final class Recipe {
    /// Display name shown anywhere the recipe is listed or shared.
    public private(set) var name = String.empty
    /// Flattened photo relation derived from `photoObjects` for quick lookup.
    @Relationship public private(set) var photos = [Photo]?.some(.empty)
    /// Ordered photo rows that preserve per-photo metadata.
    @Relationship(deleteRule: .cascade)
    public private(set) var photoObjects = [PhotoObject]?.some(.empty)
    /// Intended serving count for the recipe.
    public private(set) var servingSize = Int.zero
    /// Expected cooking time in minutes.
    public private(set) var cookingTime = Int.zero
    /// Flattened ingredient relation derived from `ingredientObjects`.
    @Relationship public private(set) var ingredients = [Ingredient]?.some(.empty)
    /// Ordered ingredient rows that preserve amount text and display order.
    @Relationship(deleteRule: .cascade)
    public private(set) var ingredientObjects = [IngredientObject]?.some(.empty)
    /// Cooking instructions in display order.
    public private(set) var steps = [String].empty
    /// Category tags used to browse and filter the recipe.
    @Relationship public private(set) var categories = [Category]?.some(.empty)
    /// Optional free-form note attached to the recipe.
    public private(set) var note = String.empty

    /// Diaries that currently surface this recipe in their flattened relation.
    @Relationship(inverse: \Diary.recipes)
    public private(set) var diaries = [Diary]?.some(.empty)
    /// Diary rows that currently point at this recipe.
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    public private(set) var diaryObjects = [DiaryObject]?.some(.empty)

    /// Timestamp captured when the recipe is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever editable recipe content changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    // swiftlint:disable function_parameter_count
    /// Inserts a recipe and derives its flattened photo and ingredient relations from the supplied child rows.
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
    /// Replaces editable recipe content, rebuilds derived relations, and refreshes `modifiedTimestamp`.
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
