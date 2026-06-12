import Foundation
import SwiftData

/// Diary use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum DiaryOperations {
    /// Returns the diary on the specified calendar day, if any.
    public static func diary(
        on date: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Diary? {
        try DiaryService.diary(
            on: date,
            context: context,
            calendar: calendar
        )
    }

    /// Returns the latest diary ordered by date and timestamps.
    public static func latestDiary(context: ModelContext) throws -> Diary? {
        try DiaryService.latestDiary(context: context)
    }

    /// Returns a random diary.
    public static func randomDiary(context: ModelContext) throws -> Diary? {
        try DiaryService.randomDiary(context: context)
    }

    /// Returns a top-of-list diary suggestion for today when one can be derived.
    public static func topSuggestion(
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current,
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(
            for: \.lastOpenedRecipeID
        )
    ) throws -> DiaryTopSuggestion? {
        try DiaryTopSuggestionService.suggestion(
            context: context,
            now: now,
            calendar: calendar,
            lastOpenedRecipeID: lastOpenedRecipeID
        )
    }

    /// Resolves the meal bucket for a given date using the canonical boundaries.
    nonisolated public static func mealType(
        for date: Date,
        calendar: Calendar = .current
    ) -> DiaryObjectType {
        DiaryTopSuggestionService.mealType(
            for: date,
            calendar: calendar
        )
    }

    /// Adds a recipe to a diary and returns follow-up hints.
    public static func addWithOutcome(
        context: ModelContext,
        date: Date,
        recipe: Recipe,
        type: DiaryObjectType
    ) throws -> MutationOutcome<Diary> {
        try DiaryService.addWithOutcome(
            context: context,
            date: date,
            recipe: recipe,
            type: type
        )
    }

    // swiftlint:disable function_parameter_count
    /// Creates a new diary and returns follow-up hints.
    public static func createWithOutcome(
        context: ModelContext,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> MutationOutcome<Diary> {
        DiaryService.createWithOutcome(
            context: context,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        )
    }

    /// Updates the specified diary and returns follow-up hints.
    public static func updateWithOutcome(
        context: ModelContext,
        diary: Diary,
        date: Date,
        breakfasts: [Recipe],
        lunches: [Recipe],
        dinners: [Recipe],
        note: String
    ) -> MutationOutcome<Diary> {
        DiaryService.updateWithOutcome(
            context: context,
            diary: diary,
            date: date,
            breakfasts: breakfasts,
            lunches: lunches,
            dinners: dinners,
            note: note
        )
    }
    // swiftlint:enable function_parameter_count

    /// Deletes the supplied diary and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        diary: Diary
    ) -> MutationOutcome<Void> {
        DiaryService.deleteWithOutcome(
            context: context,
            diary: diary
        )
    }
}
