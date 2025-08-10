import Foundation
import SwiftData

@MainActor
enum DiaryService {
    static func create(
        context: ModelContext,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> Diary {
        let objects = zip(breakfasts.indices, breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(lunches.indices, lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(dinners.indices, dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        return Diary.create(
            context: context,
            date: date,
            objects: objects,
            note: note
        )
    }

    static func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) {
        let objects = zip(breakfasts.indices, breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(lunches.indices, lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(dinners.indices, dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        diary.update(
            date: date,
            objects: objects,
            note: note
        )
    }
}

