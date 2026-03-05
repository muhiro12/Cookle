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
            var meals = mealRecipes(from: existing.objects.orEmpty)
            append(recipe: recipe, to: &meals, for: type)
            Self.update(
                context: context,
                diary: existing,
                date: date,
                breakfasts: meals.breakfasts,
                lunches: meals.lunches,
                dinners: meals.dinners,
                note: existing.note
            )
            return existing
        }
        return createNewDiary(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        )
    }
    // swiftlint:disable function_parameter_count
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
    // swiftlint:enable function_parameter_count

    /// Deletes the supplied diary from the store.
    public static func delete(
        context: ModelContext,
        diary: Diary
    ) {
        context.delete(diary)
    }
}

private extension DiaryService {
    struct MealRecipes {
        var breakfasts: [Recipe]
        var lunches: [Recipe]
        var dinners: [Recipe]
    }

    static func mealRecipes(from objects: [DiaryObject]) -> MealRecipes {
        .init(
            breakfasts: objects
                .filter { $0.type == .breakfast }
                .sorted()
                .compactMap(\.recipe),
            lunches: objects
                .filter { $0.type == .lunch }
                .sorted()
                .compactMap(\.recipe),
            dinners: objects
                .filter { $0.type == .dinner }
                .sorted()
                .compactMap(\.recipe)
        )
    }

    static func append(
        recipe: Recipe,
        to meals: inout MealRecipes,
        for type: DiaryObjectType
    ) {
        switch type {
        case .breakfast:
            meals.breakfasts.append(recipe)
        case .lunch:
            meals.lunches.append(recipe)
        case .dinner:
            meals.dinners.append(recipe)
        }
    }

    static func createNewDiary(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) -> Diary {
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
}
