@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct DiaryTopSuggestionServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func suggestion_returns_nil_when_today_diary_exists() throws {
        let calendar = makeUTCCalendar()
        let today = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 4,
                    day: 21,
                    hour: 12,
                    minute: 0
                )
            )
        )
        let recipe = Recipe.create(
            context: context,
            name: "Omelette",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = Diary.create(
            context: context,
            date: today,
            objects: [
                DiaryObject.create(
                    context: context,
                    recipe: recipe,
                    type: .lunch,
                    order: 1
                )
            ],
            note: ""
        )

        let result = try DiaryTopSuggestionService.suggestion(
            context: context,
            now: today,
            calendar: calendar,
            lastOpenedRecipeID: RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            )
        )

        #expect(result == nil)
    }

    @Test
    func suggestion_returns_nil_when_last_opened_recipe_is_missing() throws {
        let calendar = makeUTCCalendar()
        let now = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 4,
                    day: 21,
                    hour: 12,
                    minute: 0
                )
            )
        )

        let result = try DiaryTopSuggestionService.suggestion(
            context: context,
            now: now,
            calendar: calendar,
            lastOpenedRecipeID: nil
        )

        #expect(result == nil)
    }

    @Test
    func suggestion_returns_nil_when_last_opened_recipe_was_deleted() throws {
        let calendar = makeUTCCalendar()
        let now = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 4,
                    day: 21,
                    hour: 12,
                    minute: 0
                )
            )
        )
        let recipe = Recipe.create(
            context: context,
            name: "Toast",
            photos: [],
            servingSize: 1,
            cookingTime: 5,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        context.delete(recipe)

        let result = try DiaryTopSuggestionService.suggestion(
            context: context,
            now: now,
            calendar: calendar,
            lastOpenedRecipeID: stableIdentifier
        )

        #expect(result == nil)
    }

    @Test
    func suggestion_returns_candidate_for_last_opened_recipe() throws {
        let calendar = makeUTCCalendar()
        let now = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 4,
                    day: 21,
                    hour: 12,
                    minute: 0
                )
            )
        )
        let recipe = Recipe.create(
            context: context,
            name: "Spaghetti",
            photos: [],
            servingSize: 2,
            cookingTime: 15,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let stableIdentifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        let result = try DiaryTopSuggestionService.suggestion(
            context: context,
            now: now,
            calendar: calendar,
            lastOpenedRecipeID: stableIdentifier
        )

        #expect(result?.date == calendar.startOfDay(for: now))
        #expect(result?.recipeName == "Spaghetti")
        #expect(result?.recipeStableIdentifier == stableIdentifier)
        #expect(result?.mealType == .lunch)
    }

    @Test
    func mealType_uses_expected_boundaries() throws {
        let calendar = makeUTCCalendar()
        let breakfastDate = try makeDate(
            hour: 10,
            minute: 59,
            calendar: calendar
        )
        let lunchStartDate = try makeDate(
            hour: 11,
            minute: 0,
            calendar: calendar
        )
        let lunchEndDate = try makeDate(
            hour: 15,
            minute: 59,
            calendar: calendar
        )
        let dinnerDate = try makeDate(
            hour: 16,
            minute: 0,
            calendar: calendar
        )

        #expect(
            DiaryTopSuggestionService.mealType(
                for: breakfastDate,
                calendar: calendar
            ) == .breakfast
        )
        #expect(
            DiaryTopSuggestionService.mealType(
                for: lunchStartDate,
                calendar: calendar
            ) == .lunch
        )
        #expect(
            DiaryTopSuggestionService.mealType(
                for: lunchEndDate,
                calendar: calendar
            ) == .lunch
        )
        #expect(
            DiaryTopSuggestionService.mealType(
                for: dinnerDate,
                calendar: calendar
            ) == .dinner
        )
    }
}

private let kDiaryTopSuggestionTestYear = 2_026
private let kDiaryTopSuggestionTestMonth = 4
private let kDiaryTopSuggestionTestDay = 21

private func makeUTCCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}

private func makeDate(
    hour: Int,
    minute: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        calendar.date(
            from: .init(
                year: kDiaryTopSuggestionTestYear,
                month: kDiaryTopSuggestionTestMonth,
                day: kDiaryTopSuggestionTestDay,
                hour: hour,
                minute: minute
            )
        )
    )
}
