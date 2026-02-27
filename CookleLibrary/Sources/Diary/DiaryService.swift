import Foundation
import SwiftData

/// Diary-related domain services.
@preconcurrency
@MainActor
public enum DiaryService {
    /// Returns the diary on the specified calendar day, if any.
    public static func diary(on date: Date, context: ModelContext) throws -> Diary? {
        let diaries = try context.fetch(.diaries(.all))
        let cal = Calendar.current
        return diaries.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    /// Returns the latest diary ordered by date and timestamps.
    public static func latestDiary(context: ModelContext) throws -> Diary? {
        let descriptor: FetchDescriptor<Diary> = .init(
            sortBy: [
                .init(\.date, order: .reverse),
                .init(\.modifiedTimestamp, order: .reverse),
                .init(\.createdTimestamp, order: .reverse)
            ]
        )
        return try context.fetch(descriptor).first
    }

    /// Returns a random diary.
    public static func randomDiary(context: ModelContext) throws -> Diary? {
        try context.fetchRandom(.diaries(.all))
    }

    /// Adds a recipe to the diary of `date` for a given meal type, creating the diary when needed.
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
    /// Creates a new diary for the given date with provided recipes by meal type.
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

    /// Updates the specified diary with new date, items and note.
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
