//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import Foundation
import SwiftData

/// Meal item linking a recipe to a diary with type and order.
@Model
public nonisolated final class DiaryObject: SubObject {
    @Relationship
    /// Linked recipe.
    public private(set) var recipe = Recipe?.none
    /// Meal type (breakfast/lunch/dinner).
    public private(set) var type = DiaryObjectType?.none
    /// Display order within its section.
    public private(set) var order = Int.zero

    @Relationship(inverse: \Diary.objects)
    /// Owning diary (inverse relation).
    public private(set) var diary = Diary?.none

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init(recipe: Recipe, type: DiaryObjectType) {
        self.recipe = recipe
        self.type = type
    }

    /// Creates and inserts a meal item for a recipe.
    public static func create(context: ModelContext, recipe: Recipe, type: DiaryObjectType, order: Int) -> DiaryObject {
        let object = DiaryObject(recipe: recipe, type: type)
        context.insert(object)
        object.order = order
        return object
    }
}
