import Foundation
import SwiftData

@MainActor
public enum DiaryService {
    public static func diary(on date: Date, context: ModelContext) throws -> Diary? {
        let diaries = try context.fetch(.diaries(.all))
        let cal = Calendar.current
        return diaries.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    public static func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> Diary {
        if let existing = try diary(on: date, context: context) {
            let objects = existing.objects.orEmpty
            let breakfasts = objects.filter { $0.type == .breakfast }.sorted().compactMap(\.recipe)
            let lunches = objects.filter { $0.type == .lunch }.sorted().compactMap(\.recipe)
            let dinners = objects.filter { $0.type == .dinner }.sorted().compactMap(\.recipe)

            switch type {
            case .breakfast:
                Self.update(
                    context: context,
                    diary: existing,
                    date: date,
                    breakfasts: breakfasts + [recipe],
                    lunches: lunches,
                    dinners: dinners,
                    note: existing.note
                )
            case .lunch:
                Self.update(
                    context: context,
                    diary: existing,
                    date: date,
                    breakfasts: breakfasts,
                    lunches: lunches + [recipe],
                    dinners: dinners,
                    note: existing.note
                )
            case .dinner:
                Self.update(
                    context: context,
                    diary: existing,
                    date: date,
                    breakfasts: breakfasts,
                    lunches: lunches,
                    dinners: dinners + [recipe],
                    note: existing.note
                )
            }
            return existing
        }
        switch type {
        case .breakfast:
            return Self.create(
                context: context,
                date: date,
                breakfasts: [recipe],
                lunches: [],
                dinners: [],
                note: ""
            )
        case .lunch:
            return Self.create(
                context: context,
                date: date,
                breakfasts: [],
                lunches: [recipe],
                dinners: [],
                note: ""
            )
        case .dinner:
            return Self.create(
                context: context,
                date: date,
                breakfasts: [],
                lunches: [],
                dinners: [recipe],
                note: ""
            )
        }
    }
    public static func create(
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

    public static func update(
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
