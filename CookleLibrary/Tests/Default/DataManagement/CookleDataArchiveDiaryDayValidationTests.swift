@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct CookleDataArchiveDiaryDayValidationTests {
    @Test
    func validatedArchive_throws_when_diaries_share_calendar_day() {
        let calendar = makeArchiveDiaryDayTestCalendar()

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: try encodedData(
                    from: duplicateDiaryDayArchive()
                ),
                calendar: calendar
            )
            Issue.record("Expected archive validation to fail.")
        } catch CookleDataArchiveService.ArchiveError.duplicateDiaryDay {
            // Expected failure.
        } catch {
            Issue.record(error)
        }
    }

    private func encodedData(
        from archive: CookleDataArchive
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(
            archive
        )
    }

    private func duplicateDiaryDayArchive() -> CookleDataArchive {
        let laterDate = TestArchive.diaryDate.addingTimeInterval(
            kArchiveDiaryDayTestTimeDifference
        )
        return .init(
            formatVersion: CookleDataArchive.currentFormatVersion,
            exportedAt: .now,
            ingredients: [],
            categories: [],
            photos: [],
            recipes: [],
            diaries: [
                diaryRecord(
                    id: "diary-1",
                    date: TestArchive.diaryDate
                ),
                diaryRecord(
                    id: "diary-2",
                    date: laterDate
                )
            ]
        )
    }

    private func diaryRecord(
        id: String,
        date: Date
    ) -> CookleDataArchive.DiaryRecord {
        .init(
            id: id,
            date: date,
            objects: [],
            note: "",
            createdTimestamp: date,
            modifiedTimestamp: date
        )
    }
}

private let kArchiveDiaryDayTestTimeDifference: TimeInterval = 3_600

private func makeArchiveDiaryDayTestCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}
