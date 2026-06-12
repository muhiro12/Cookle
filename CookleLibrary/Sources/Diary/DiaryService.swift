import Foundation
import SwiftData

/// Internal diary collaborator used by public Operations.
@preconcurrency
@MainActor
enum DiaryService {
    /// Returns the diary on the specified calendar day, if any.
    static func diary(
        on date: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Diary? {
        let diaries = try context.fetch(.diaries(.all))
        return diaries.first { diary in
            calendar.isDate(
                diary.date,
                inSameDayAs: date
            )
        }
    }

    /// Returns the latest diary ordered by date and timestamps.
    static func latestDiary(context: ModelContext) throws -> Diary? {
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
    static func randomDiary(context: ModelContext) throws -> Diary? {
        try context.fetchRandom(.diaries(.all))
    }

    /// Adds a recipe to the diary of `date` for a given meal type, creating the diary when needed.
    static func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> Diary {
        try addWithOutcome(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        ).value
    }

    /// Adds a recipe to a diary and returns follow-up hints.
    static func addWithOutcome(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> MutationOutcome<Diary> {
        if let existing = try diary(on: date, context: context) {
            var meals = mealRecipes(from: existing.objects.orEmpty)
            append(recipe: recipe, to: &meals, for: type)
            let outcome = Self.updateWithOutcome(
                context: context,
                diary: existing,
                date: date,
                breakfasts: meals.breakfasts,
                lunches: meals.lunches,
                dinners: meals.dinners,
                note: existing.note
            )
            return .init(
                value: existing,
                effects: outcome.effects
            )
        }
        return createNewDiaryOutcome(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        )
    }
    // swiftlint:disable function_parameter_count
    /// Creates a new diary for the given date with provided recipes by meal type.
    static func create(
        context: ModelContext,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> Diary {
        createWithOutcome(
            context: context,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        ).value
    }

    /// Creates a new diary and returns follow-up hints.
    static func createWithOutcome(
        context: ModelContext,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> MutationOutcome<Diary> {
        let objects = zip(breakfasts.indices, breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(lunches.indices, lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(dinners.indices, dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        let diary = Diary.create(
            context: context,
            date: date,
            objects: objects,
            note: note
        )
        return .init(
            value: diary,
            effects: diaryMutationEffects
        )
    }

    /// Updates the specified diary with new date, items and note.
    static func update(
        context: ModelContext,
        diary: Diary,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) {
        _ = updateWithOutcome(
            context: context,
            diary: diary,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        )
    }

    /// Updates the specified diary and returns follow-up hints.
    static func updateWithOutcome(
        context: ModelContext,
        diary: Diary,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> MutationOutcome<Diary> {
        let previousObjects = diary.objects.orEmpty
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
        previousObjects.forEach(context.delete)
        return .init(
            value: diary,
            effects: diaryMutationEffects
        )
    }
    // swiftlint:enable function_parameter_count

    /// Deletes the supplied diary from the store.
    static func delete(
        context: ModelContext,
        diary: Diary
    ) {
        _ = deleteWithOutcome(
            context: context,
            diary: diary
        )
    }

    /// Deletes the supplied diary and returns follow-up hints.
    static func deleteWithOutcome(
        context: ModelContext,
        diary: Diary
    ) -> MutationOutcome<Void> {
        context.delete(diary)
        return .init(
            value: (),
            effects: diaryMutationEffects
        )
    }
}

private extension DiaryService {
    struct MealRecipes {
        var breakfasts: [Recipe]
        var lunches: [Recipe]
        var dinners: [Recipe]
    }

    static var diaryMutationEffects: MutationEffect {
        [
            .diaryDataChanged
        ]
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

    static func createNewDiaryOutcome(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) -> MutationOutcome<Diary> {
        switch type {
        case .breakfast:
            return Self.createWithOutcome(
                context: context,
                date: date,
                breakfasts: [recipe],
                lunches: [],
                dinners: [],
                note: ""
            )
        case .lunch:
            return Self.createWithOutcome(
                context: context,
                date: date,
                breakfasts: [],
                lunches: [recipe],
                dinners: [],
                note: ""
            )
        case .dinner:
            return Self.createWithOutcome(
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
