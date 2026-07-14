@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiaryDayUniquenessTests {
    let context: ModelContext = makeTestContext()

    @Test
    func create_rejects_second_diary_on_same_calendar_day() throws {
        let calendar = makeDiaryDayTestCalendar()
        let morning = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestMorningHour,
            calendar: calendar
        )
        let evening = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestEveningHour,
            calendar: calendar
        )
        _ = try DiaryService.create(
            context: context,
            input: .init(
                date: morning,
                note: "Morning"
            ),
            calendar: calendar
        )

        do {
            _ = try DiaryService.create(
                context: context,
                input: .init(
                    date: evening,
                    note: "Evening"
                ),
                calendar: calendar
            )
            Issue.record("Expected diary creation to fail.")
        } catch DiaryDayConflictError.dayAlreadyOccupied {
            // Expected failure.
        } catch {
            Issue.record(error)
        }

        let diaries = try context.fetch(.diaries(.all))
        #expect(diaries.count == 1)
        #expect(diaries.first?.note == "Morning")
    }

    @Test
    func update_rejects_date_occupied_by_another_diary() throws {
        let calendar = makeDiaryDayTestCalendar()
        let firstDate = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestMorningHour,
            calendar: calendar
        )
        let secondDate = try makeDiaryDayTestDate(
            day: kDiaryDayTestSecondDay,
            hour: kDiaryDayTestMorningHour,
            calendar: calendar
        )
        _ = try DiaryService.create(
            context: context,
            input: .init(
                date: firstDate,
                note: "First"
            ),
            calendar: calendar
        )
        let secondDiary = try DiaryService.create(
            context: context,
            input: .init(
                date: secondDate,
                note: "Second"
            ),
            calendar: calendar
        )

        do {
            try DiaryService.update(
                context: context,
                diary: secondDiary,
                input: .init(
                    date: firstDate,
                    note: "Conflicting update"
                ),
                calendar: calendar
            )
            Issue.record("Expected diary update to fail.")
        } catch DiaryDayConflictError.dayAlreadyOccupied {
            // Expected failure.
        } catch {
            Issue.record(error)
        }

        #expect(secondDiary.date == secondDate)
        #expect(secondDiary.note == "Second")
        #expect((secondDiary.objects ?? []).isEmpty)
        #expect(try context.fetch(FetchDescriptor<DiaryObject>()).isEmpty)
    }

    @Test
    func lookup_uses_deterministic_latest_diary_when_legacy_duplicates_exist() throws {
        let calendar = makeDiaryDayTestCalendar()
        let morning = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestMorningHour,
            calendar: calendar
        )
        let evening = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestEveningHour,
            calendar: calendar
        )
        let morningDiary = insertDiary(
            date: morning,
            note: "Morning"
        )
        let eveningDiary = insertDiary(
            date: evening,
            note: "Evening"
        )

        let resolvedDiary = try DiaryService.diary(
            on: morning,
            context: context,
            calendar: calendar
        )

        #expect(resolvedDiary === eveningDiary)
        #expect(resolvedDiary !== morningDiary)
    }

    @Test
    func update_allows_legacy_duplicate_to_keep_its_calendar_day() throws {
        let calendar = makeDiaryDayTestCalendar()
        let morning = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestMorningHour,
            calendar: calendar
        )
        let evening = try makeDiaryDayTestDate(
            day: kDiaryDayTestFirstDay,
            hour: kDiaryDayTestEveningHour,
            calendar: calendar
        )
        let morningDiary = insertDiary(
            date: morning,
            note: "Morning"
        )
        _ = insertDiary(
            date: evening,
            note: "Evening"
        )

        try DiaryService.update(
            context: context,
            diary: morningDiary,
            input: .init(
                date: morning,
                note: "Updated morning"
            ),
            calendar: calendar
        )

        #expect(morningDiary.note == "Updated morning")
    }

    private func insertDiary(
        date: Date,
        note: String
    ) -> Diary {
        Diary.create(
            context: context,
            content: .init(
                date: date,
                objects: [],
                note: note
            )
        )
    }
}

private let kDiaryDayTestYear = 2_026
private let kDiaryDayTestMonth = 7
private let kDiaryDayTestFirstDay = 14
private let kDiaryDayTestSecondDay = 15
private let kDiaryDayTestMorningHour = 8
private let kDiaryDayTestEveningHour = 20

private func makeDiaryDayTestCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}

private func makeDiaryDayTestDate(
    day: Int,
    hour: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        calendar.date(
            from: .init(
                year: kDiaryDayTestYear,
                month: kDiaryDayTestMonth,
                day: day,
                hour: hour
            )
        )
    )
}
