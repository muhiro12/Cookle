//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import Foundation
import SwiftData

@Model
final class DiaryObject {
    @Relationship(inverse: \Recipe.diaryObjects)
    private(set) var recipe: Recipe!
    private(set) var type: DiaryObjectType!
    private(set) var order: Int!
    @Relationship
    private(set) var diary: Diary?
    private(set) var createdTimestamp: Date!
    private(set) var modifiedTimestamp: Date!

    private init(recipe: Recipe, type: DiaryObjectType) {
        self.recipe = recipe
        self.type = type
        self.order = .zero
        self.diary = nil
        self.createdTimestamp = .now
        self.modifiedTimestamp = .now
    }

    static func create(context: ModelContext, recipe: Recipe, type: DiaryObjectType, order: Int) -> DiaryObject {
        let object = DiaryObject(recipe: recipe, type: type)
        context.insert(object)
        object.order = order
        return object
    }
}

extension DiaryObject {
    static var descriptor: FetchDescriptor<DiaryObject> {
        .init(
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse)
            ]
        )
    }
}
