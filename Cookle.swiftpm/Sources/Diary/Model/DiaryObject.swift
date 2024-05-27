//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import SwiftData

@Model
final class DiaryObject {
    private(set) var type: DiaryObjectType!
    @Relationship(deleteRule: .nullify, inverse: \Recipe.diaryObjects)
    private(set) var recipes: [Recipe]!
    @Relationship(deleteRule: .nullify)
    private(set) var diary: Diary?

    private init(type: DiaryObjectType) {
        self.type = type
        self.recipes = []
        self.diary = nil
    }

    static func create(context: ModelContext, type: DiaryObjectType, recipes: [Recipe]) -> DiaryObject {
        let object = DiaryObject(type: type)
        context.insert(object)
        object.recipes = recipes
        return object
    }
}

extension DiaryObject {
    static var descriptor: FetchDescriptor<DiaryObject> {
        .init(
            sortBy: [
                .init(\.diary?.date, order: .reverse)
            ]
        )
    }
}
