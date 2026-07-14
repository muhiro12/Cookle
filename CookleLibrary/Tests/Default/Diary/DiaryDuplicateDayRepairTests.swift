@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiaryDuplicateDayRepairTests {
    @Test
    func report_countsConflictingDaysAndExcessDiaries() throws {
        let context = makeTestContext()
        let calendar = makeDuplicateDiaryTestCalendar()
        let firstDay = try makeDuplicateDiaryTestDate(
            day: 14,
            hour: 8,
            calendar: calendar
        )
        let secondDay = try makeDuplicateDiaryTestDate(
            day: 15,
            hour: 8,
            calendar: calendar
        )
        insertDuplicateDiary(date: firstDay, context: context)
        insertDuplicateDiary(
            date: firstDay.addingTimeInterval(3_600),
            context: context
        )
        insertDuplicateDiary(date: secondDay, context: context)
        insertDuplicateDiary(
            date: secondDay.addingTimeInterval(3_600),
            context: context
        )
        insertDuplicateDiary(
            date: secondDay.addingTimeInterval(7_200),
            context: context
        )

        let report = try DiaryService.duplicateDayReport(
            context: context,
            calendar: calendar
        )

        #expect(report.conflictingDayCount == 2)
        #expect(report.excessDiaryCount == 3)
        #expect(report.hasConflicts)
    }

    @Test
    func repair_preservesDistinctNotesAndDeduplicatesMealRows() throws {
        let context = makeTestContext()
        let calendar = makeDuplicateDiaryTestCalendar()
        let day = try makeDuplicateDiaryTestDate(
            day: 14,
            hour: 8,
            calendar: calendar
        )
        let soup = makeDuplicateDiaryRecipe(
            name: "Soup",
            context: context
        )
        let bread = makeDuplicateDiaryRecipe(
            name: "Bread",
            context: context
        )
        insertDuplicateDiary(
            date: day,
            context: context,
            breakfasts: [soup],
            note: "Morning note"
        )
        insertDuplicateDiary(
            date: day.addingTimeInterval(43_200),
            context: context,
            breakfasts: [soup, bread],
            note: "Evening note"
        )

        let outcome = try DiaryService.repairDuplicateDaysWithOutcome(
            context: context,
            calendar: calendar
        )
        try context.save()

        let diaries = try context.fetch(.diaries(.all))
        let repairedDiary = try #require(diaries.first)
        let breakfastObjects = (repairedDiary.objects ?? [])
            .filter { object in
                object.type == .breakfast
            }
            .sorted()

        #expect(outcome.value.mergedDayCount == 1)
        #expect(outcome.value.removedDiaryCount == 1)
        #expect(outcome.effects.contains(.diaryDataChanged))
        #expect(diaries.count == 1)
        #expect(repairedDiary.note == "Evening note\n\nMorning note")
        #expect(breakfastObjects.compactMap(\.recipe?.name) == ["Soup", "Bread"])
        #expect(breakfastObjects.map(\.order) == [1, 2])
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<DiaryObject>()) == 2)
    }

    @Test
    func repair_isIdempotentAfterFirstMerge() throws {
        let context = makeTestContext()
        let calendar = makeDuplicateDiaryTestCalendar()
        let day = try makeDuplicateDiaryTestDate(
            day: 14,
            hour: 8,
            calendar: calendar
        )
        insertDuplicateDiary(date: day, context: context)
        insertDuplicateDiary(
            date: day.addingTimeInterval(3_600),
            context: context
        )

        let firstOutcome = try DiaryService.repairDuplicateDaysWithOutcome(
            context: context,
            calendar: calendar
        )
        try context.save()
        let secondOutcome = try DiaryService.repairDuplicateDaysWithOutcome(
            context: context,
            calendar: calendar
        )

        #expect(firstOutcome.value.mergedDayCount == 1)
        #expect(secondOutcome.value == .init(mergedDayCount: 0, removedDiaryCount: 0))
        #expect(secondOutcome.effects.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<Diary>()) == 1)
    }
}

@MainActor
private func insertDuplicateDiary(
    date: Date,
    context: ModelContext,
    breakfasts: [Recipe] = [],
    note: String = ""
) {
    let objects = breakfasts.enumerated().map { index, recipe in
        DiaryObject.create(
            context: context,
            recipe: recipe,
            type: .breakfast,
            order: index + 1
        )
    }
    _ = Diary.create(
        context: context,
        content: .init(
            date: date,
            objects: objects,
            note: note
        )
    )
}

@MainActor
private func makeDuplicateDiaryRecipe(
    name: String,
    context: ModelContext
) -> Recipe {
    Recipe.create(
        context: context,
        content: .init(
            name: name,
            photos: [],
            servingSize: 1,
            cookingTime: kDuplicateDiaryCookingTime,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    )
}

private func makeDuplicateDiaryTestCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}

private func makeDuplicateDiaryTestDate(
    day: Int,
    hour: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        calendar.date(
            from: .init(
                year: kDuplicateDiaryTestYear,
                month: kDuplicateDiaryTestMonth,
                day: day,
                hour: hour
            )
        )
    )
}

private let kDuplicateDiaryCookingTime = 10
private let kDuplicateDiaryTestYear = 2_026
private let kDuplicateDiaryTestMonth = 7
