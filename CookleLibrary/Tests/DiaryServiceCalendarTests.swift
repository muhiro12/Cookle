@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct DiaryServiceCalendarTests {
    let context: ModelContext = makeTestContext()

    @Test
    func diary_lookup_uses_supplied_calendar_for_same_day_check() throws {
        let utcCalendar = makeUTCCalendar()
        let losAngelesCalendar = try makeCalendar(
            timeZoneIdentifier: "America/Los_Angeles"
        )
        let now = try makeDate(
            hour: 12,
            minute: 0,
            calendar: utcCalendar
        )
        insertLunchDiary(
            recipeName: "Omelette",
            date: now,
            context: context
        )

        let utcMatch = try DiaryService.diary(
            on: utcCalendar.startOfDay(for: now),
            context: context,
            calendar: utcCalendar
        )
        let losAngelesMatch = try DiaryService.diary(
            on: utcCalendar.startOfDay(for: now),
            context: context,
            calendar: losAngelesCalendar
        )

        #expect(utcMatch != nil)
        #expect(losAngelesMatch == nil)
    }
}

private let kDiaryServiceCalendarTestYear = 2_026
private let kDiaryServiceCalendarTestMonth = 4
private let kDiaryServiceCalendarTestDay = 21
private let kDiaryServiceCalendarTestServingSize = 1
private let kDiaryServiceCalendarTestCookingTime = 10
private let kLunchDisplayOrder = 1

private func makeUTCCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}

private func makeCalendar(
    timeZoneIdentifier: String
) throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(
        TimeZone(identifier: timeZoneIdentifier)
    )
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
                year: kDiaryServiceCalendarTestYear,
                month: kDiaryServiceCalendarTestMonth,
                day: kDiaryServiceCalendarTestDay,
                hour: hour,
                minute: minute
            )
        )
    )
}

private func insertLunchDiary(
    recipeName: String,
    date: Date,
    context: ModelContext
) {
    let recipe = Recipe.create(
        context: context,
        content: .init(
            name: recipeName,
            photos: [],
            servingSize: kDiaryServiceCalendarTestServingSize,
            cookingTime: kDiaryServiceCalendarTestCookingTime,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    )
    _ = Diary.create(
        context: context,
        content: .init(
            date: date,
            objects: [
                DiaryObject.create(
                    context: context,
                    recipe: recipe,
                    type: .lunch,
                    order: kLunchDisplayOrder
                )
            ],
            note: ""
        )
    )
}
