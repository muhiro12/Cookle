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
        try diaries(
            on: date,
            context: context,
            calendar: calendar
        )
        .first
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
        try context.fetch(.diaries(.all)).randomElement()
    }

    /// Reports calendar days represented by multiple persisted diaries.
    static func duplicateDayReport(
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> DiaryDayConflictReport {
        try DiaryDuplicateDayService.report(
            context: context,
            calendar: calendar
        )
    }

    /// Merges every duplicate-day group while preserving distinct notes and meal rows.
    static func repairDuplicateDaysWithOutcome(
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> MutationOutcome<DiaryDayRepairSummary> {
        try DiaryDuplicateDayService.repairWithOutcome(
            context: context,
            calendar: calendar
        )
    }

    /// Adds a recipe to the diary of `date` for a given meal type, creating the diary when needed.
    static func add(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType,
        calendar: Calendar = .current
    ) throws -> Diary {
        try addWithOutcome(
            context: context,
            date: date,
            recipe: recipe,
            type: type,
            calendar: calendar
        ).value
    }

    /// Adds a recipe to a diary and returns follow-up hints.
    static func addWithOutcome(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType,
        calendar: Calendar = .current
    ) throws -> MutationOutcome<Diary> {
        if let existing = try diary(
            on: date,
            context: context,
            calendar: calendar
        ) {
            var meals = mealRecipes(from: (existing.objects ?? []))
            append(recipe: recipe, to: &meals, for: type)
            let outcome = try Self.updateWithOutcome(
                context: context,
                diary: existing,
                input: .init(
                    date: date,
                    breakfasts: meals.breakfasts,
                    lunches: meals.lunches,
                    dinners: meals.dinners,
                    note: existing.note
                ),
                calendar: calendar
            )
            return .init(
                value: existing,
                effects: outcome.effects
            )
        }
        return try createNewDiaryOutcome(
            context: context,
            date: date,
            recipe: recipe,
            type: type,
            calendar: calendar
        )
    }
    /// Creates a new diary for the given date with provided recipes by meal type.
    static func create(
        context: ModelContext,
        input: DiaryFormInput,
        calendar: Calendar = .current
    ) throws -> Diary {
        try createWithOutcome(
            context: context,
            input: input,
            calendar: calendar
        ).value
    }

    /// Creates a new diary and returns follow-up hints.
    static func createWithOutcome(
        context: ModelContext,
        input: DiaryFormInput,
        calendar: Calendar = .current
    ) throws -> MutationOutcome<Diary> {
        guard try diaries(
            on: input.date,
            context: context,
            calendar: calendar
        ).isEmpty else {
            throw DiaryDayConflictError.dayAlreadyOccupied
        }

        let objects = zip(input.breakfasts.indices, input.breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(input.lunches.indices, input.lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(input.dinners.indices, input.dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        let diary = Diary.create(
            context: context,
            content: .init(
                date: input.date,
                objects: objects,
                note: input.note
            )
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
        input: DiaryFormInput,
        calendar: Calendar = .current
    ) throws {
        _ = try updateWithOutcome(
            context: context,
            diary: diary,
            input: input,
            calendar: calendar
        )
    }

    /// Updates the specified diary and returns follow-up hints.
    static func updateWithOutcome(
        context: ModelContext,
        diary: Diary,
        input: DiaryFormInput,
        calendar: Calendar = .current
    ) throws -> MutationOutcome<Diary> {
        let isKeepingCalendarDay = calendar.isDate(
            diary.date,
            inSameDayAs: input.date
        )
        let conflictingDiaryExists = if isKeepingCalendarDay {
            false
        } else {
            try diaries(
                on: input.date,
                context: context,
                calendar: calendar
            ).contains { existingDiary in
                existingDiary !== diary
            }
        }
        guard conflictingDiaryExists == false else {
            throw DiaryDayConflictError.dayAlreadyOccupied
        }

        let previousObjects = (diary.objects ?? [])
        let objects = zip(input.breakfasts.indices, input.breakfasts).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .breakfast, order: index + 1)
        } + zip(input.lunches.indices, input.lunches).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .lunch, order: index + 1)
        } + zip(input.dinners.indices, input.dinners).map { index, recipe in
            DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: index + 1)
        }
        diary.update(
            content: .init(
                date: input.date,
                objects: objects,
                note: input.note
            )
        )
        previousObjects.forEach(context.delete)
        return .init(
            value: diary,
            effects: diaryMutationEffects
        )
    }
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
        type: DiaryObjectType,
        calendar: Calendar
    ) throws -> MutationOutcome<Diary> {
        switch type {
        case .breakfast:
            return try Self.createWithOutcome(
                context: context,
                input: .init(
                    date: date,
                    breakfasts: [recipe]
                ),
                calendar: calendar
            )
        case .lunch:
            return try Self.createWithOutcome(
                context: context,
                input: .init(
                    date: date,
                    lunches: [recipe]
                ),
                calendar: calendar
            )
        case .dinner:
            return try Self.createWithOutcome(
                context: context,
                input: .init(
                    date: date,
                    dinners: [recipe]
                ),
                calendar: calendar
            )
        }
    }

    static func diaries(
        on date: Date,
        context: ModelContext,
        calendar: Calendar
    ) throws -> [Diary] {
        let matchingDiaries = try context.fetch(.diaries(.all)).filter { diary in
            calendar.isDate(
                diary.date,
                inSameDayAs: date
            )
        }
        return DiaryDuplicateDayService.orderedDiaries(
            matchingDiaries
        )
    }
}
