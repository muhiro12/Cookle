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
    public private(set) var name = ""
    /// Flattened photo relation derived from `photoObjects` for quick lookup.
    @Relationship public private(set) var photos = [Photo]?.some([])
    /// Ordered photo rows that preserve per-photo metadata.
    @Relationship(deleteRule: .cascade)
    public private(set) var photoObjects = [PhotoObject]?.some([])
    /// Intended serving count for the recipe.
    public private(set) var servingSize = Int.zero
    /// Expected cooking time in minutes.
    public private(set) var cookingTime = Int.zero
    /// Flattened ingredient relation derived from `ingredientObjects`.
    @Relationship public private(set) var ingredients = [Ingredient]?.some([])
    /// Ordered ingredient rows that preserve amount text and display order.
    @Relationship(deleteRule: .cascade)
    public private(set) var ingredientObjects = [IngredientObject]?.some([])
    /// Cooking instructions in display order.
    public private(set) var steps = [String]()
    /// Category tags used to browse and filter the recipe.
    @Relationship public private(set) var categories = [Category]?.some([])
    /// Optional free-form note attached to the recipe.
    public private(set) var note = ""

    /// Diaries that currently surface this recipe in their flattened relation.
    @Relationship(inverse: \Diary.recipes)
    public private(set) var diaries = [Diary]?.some([])
    /// Diary rows that currently point at this recipe.
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.recipe)
    public private(set) var diaryObjects = [DiaryObject]?.some([])

    /// Timestamp captured when the recipe is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever editable recipe content changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Inserts a recipe and derives its flattened photo and ingredient relations from supplied content.
    /// - Parameters:
    ///   - context: Model context to insert into.
    ///   - content: Editable recipe content.
    /// - Returns: The newly created `Recipe`.
    public static func create(
        context: ModelContext,
        content: RecipeContent
    ) -> Recipe {
        let recipe = Recipe()
        context.insert(recipe)
        recipe.apply(content)
        return recipe
    }

    static func restore(
        context: ModelContext,
        content: RecipeContent,
        timestamps: PersistentTimestamps
    ) -> Recipe {
        let recipe = create(
            context: context,
            content: content
        )
        recipe.createdTimestamp = timestamps.created
        recipe.modifiedTimestamp = timestamps.modified
        return recipe
    }

    /// Replaces editable recipe content, rebuilds derived relations, and refreshes `modifiedTimestamp`.
    public func update(content: RecipeContent) {
        apply(content)
        self.modifiedTimestamp = .now
    }

    /// Replaces only category tags while keeping the rest of the recipe content unchanged.
    public func updateCategories(_ categories: [Category]) {
        self.categories = categories
        self.modifiedTimestamp = .now
    }

    /// Rebuilds flattened ingredient relations from the ordered ingredient rows.
    public func refreshIngredients() {
        self.ingredients = (ingredientObjects ?? []).compactMap(\.ingredient)
        self.modifiedTimestamp = .now
    }
}

extension Recipe {
    var content: RecipeContent {
        .init(
            name: name,
            photos: photoObjects ?? [],
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredientObjects ?? [],
            steps: steps,
            categories: categories ?? [],
            note: note
        )
    }

    private func apply(_ content: RecipeContent) {
        self.name = content.name
        self.photos = content.photos.compactMap(\.photo)
        self.photoObjects = content.photos
        self.servingSize = content.servingSize
        self.cookingTime = content.cookingTime
        self.ingredients = content.ingredients.compactMap(\.ingredient)
        self.ingredientObjects = content.ingredients
        self.steps = content.steps
        self.categories = content.categories
        self.note = content.note
    }
}

extension Recipe: Identifiable {}
