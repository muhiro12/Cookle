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
    private(set) var recipes: [Recipe]!
    @Relationship(inverse: \Diary.objects)
    private(set) var diary: Diary?

    private init(type: DiaryType, recipes: [Recipe]) {
        self.type = type
        self.recipes = recipes
    }

    static func create(context: ModelContext, type: DiaryType, recipes: [Recipe]) -> DiaryObject {
        let object = DiaryObject(type: type, recipes: recipes)
        context.insert(object)
        return object
    }
}
