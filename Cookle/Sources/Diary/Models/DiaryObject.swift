//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import Foundation
import SwiftData

@Model
nonisolated final class DiaryObject: SubObject {
    @Relationship
    private(set) var recipe = Recipe?.none
    private(set) var type = DiaryObjectType?.none
    private(set) var order = Int.zero

    @Relationship(inverse: \Diary.objects)
    private(set) var diary = Diary?.none

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init(recipe: Recipe, type: DiaryObjectType) {
        self.recipe = recipe
        self.type = type
    }

    static func create(context: ModelContext, recipe: Recipe, type: DiaryObjectType, order: Int) -> DiaryObject {
        let object = DiaryObject(recipe: recipe, type: type)
        context.insert(object)
        object.order = order
        return object
    }
}
