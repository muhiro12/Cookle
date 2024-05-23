//
//  DiaryObject.swift
//
//
//  Created by Hiromu Nakano on 2024/05/22.
//

import SwiftData

@Model
final class DiaryObject {
    enum DiaryType: Codable {
        case breakfast
        case lunch
        case dinner
    }

    private(set) var type: DiaryType!
    @Relationship(inverse: \Recipe.diaryObjects)
    private(set) var recipes: [Recipe]!
    private(set) var diary: Diary?

    private init() {}

    static func create(context: ModelContext, type: DiaryType, recipes: [Recipe]) -> DiaryObject {
        let object = DiaryObject()
        context.insert(object)

        object.type = type
        object.recipes = recipes
        object.diary = nil

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
