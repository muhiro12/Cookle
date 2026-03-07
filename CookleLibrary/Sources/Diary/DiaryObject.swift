//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import Foundation
import SwiftData

/// Persisted meal row that places a recipe into a diary section and order slot.
@Model
nonisolated public final class DiaryObject: SubObject {
    /// Recipe shown by this meal row.
    @Relationship public private(set) var recipe = Recipe?.none
    /// Meal section this row belongs to.
    public private(set) var type = DiaryObjectType?.none
    /// Position of the row within the selected meal section.
    public private(set) var order = Int.zero

    /// Diary that owns this meal row.
    @Relationship(inverse: \Diary.objects)
    public private(set) var diary = Diary?.none

    /// Timestamp captured when the meal row is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp initialized with the row for recency-based queries.
    public private(set) var modifiedTimestamp = Date.now

    private init(recipe: Recipe, type: DiaryObjectType) {
        self.recipe = recipe
        self.type = type
    }

    /// Inserts a meal row for a recipe in the supplied section and order.
    public static func create(context: ModelContext, recipe: Recipe, type: DiaryObjectType, order: Int) -> DiaryObject {
        let object = DiaryObject(recipe: recipe, type: type)
        context.insert(object)
        object.order = order
        return object
    }
}
