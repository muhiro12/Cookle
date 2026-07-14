@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct ArchiveEncodedResourceLimitTests {
    private typealias Support = ArchiveResourceLimitTestSupport

    @Test
    func encodedArchive_throws_when_current_data_exceeds_semantic_limit() throws {
        let context = makeTestContext()
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Existing",
                photos: [],
                servingSize: 1,
                cookingTime: 1,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()

        do {
            _ = try CookleDataArchiveService.encodedArchive(
                from: context,
                limits: Support.makeLimits(
                    maximumTextByteCount: 1
                )
            )
            Issue.record("Expected exported text byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .text)
            #expect(actualByteCount == "Existing".utf8.count)
            #expect(maximumByteCount == 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func encodedArchive_throws_when_encoded_output_exceeds_limit() {
        let context = makeTestContext()

        do {
            _ = try CookleDataArchiveService.encodedArchive(
                from: context,
                limits: Support.makeLimits(
                    maximumEncodedByteCount: 1
                )
            )
            Issue.record("Expected exported backup byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .encodedData)
            #expect(actualByteCount > maximumByteCount)
            #expect(maximumByteCount == 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_accepts_encoded_data_at_limit() throws {
        let archive = Support.makeArchive()
        let data = try Support.encodedData(
            from: archive
        )

        let validatedArchive = try CookleDataArchiveService.validatedArchive(
            from: data,
            limits: Support.makeLimits(
                maximumEncodedByteCount: data.count
            )
        )

        #expect(validatedArchive.formatVersion == archive.formatVersion)
    }

    @Test
    func decodedArchive_throws_when_encoded_data_exceeds_limit() throws {
        let data = try Support.encodedData(
            from: Support.makeArchive()
        )
        let maximumEncodedByteCount = data.count - 1

        do {
            _ = try CookleDataArchiveService.decodedArchive(
                from: data,
                limits: Support.makeLimits(
                    maximumEncodedByteCount: maximumEncodedByteCount
                )
            )
            Issue.record("Expected encoded backup data validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .encodedData)
            #expect(actualByteCount == data.count)
            #expect(maximumByteCount == maximumEncodedByteCount)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func encodedArchive_rejectsLegacyDuplicateDiaryDays() {
        let context = makeTestContext()
        let morning = Date(timeIntervalSinceReferenceDate: 100_000)
        _ = Diary.create(
            context: context,
            content: .init(
                date: morning,
                objects: [],
                note: "Morning"
            )
        )
        _ = Diary.create(
            context: context,
            content: .init(
                date: morning.addingTimeInterval(3_600),
                objects: [],
                note: "Evening"
            )
        )

        do {
            _ = try CookleDataArchiveService.encodedArchive(
                from: context,
                calendar: makeEncodedArchiveTestCalendar()
            )
            Issue.record("Expected duplicate diary validation to fail before export.")
        } catch CookleDataArchiveService.ArchiveError.duplicateDiaryDay {
            // Expected failure.
        } catch {
            Issue.record(error)
        }
    }
}

private func makeEncodedArchiveTestCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
    return calendar
}
