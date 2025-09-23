//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import Foundation
import SwiftData

@Model
public nonisolated final class DiaryObject: SubObject {
    @Relationship
    public private(set) var recipe = Recipe?.none
    public private(set) var type = DiaryObjectType?.none
    public private(set) var order = Int.zero

    @Relationship(inverse: \Diary.objects)
    public private(set) var diary = Diary?.none

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init(recipe: Recipe, type: DiaryObjectType) {
        self.recipe = recipe
        self.type = type
    }

    public static func create(context: ModelContext, recipe: Recipe, type: DiaryObjectType, order: Int) -> DiaryObject {
        let object = DiaryObject(recipe: recipe, type: type)
        context.insert(object)
        object.order = order
        return object
    }
}
