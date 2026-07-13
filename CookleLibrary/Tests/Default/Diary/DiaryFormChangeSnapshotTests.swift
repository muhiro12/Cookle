@testable import CookleLibrary
import Foundation
import Testing

struct DiaryFormChangeSnapshotTests {
    @Test
    func sameCalendarDayAndMealSetsAreNotChanges() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(identifier: "America/Los_Angeles")
        )
        let morning = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 3,
                    day: 8,
                    hour: 8
                )
            )
        )
        let evening = try #require(
            calendar.date(
                from: .init(
                    year: 2_026,
                    month: 3,
                    day: 8,
                    hour: 20
                )
            )
        )

        let initialSnapshot = DiaryFormChangeSnapshot(
            date: morning,
            breakfastRecipeIDs: ["b", "a"],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: ["c"],
            note: "Note",
            calendar: calendar
        )
        let currentSnapshot = DiaryFormChangeSnapshot(
            date: evening,
            breakfastRecipeIDs: ["a", "b"],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: ["c"],
            note: "Note",
            calendar: calendar
        )

        #expect(currentSnapshot == initialSnapshot)
    }

    @Test
    func movingARecipeBetweenMealsIsAChange() {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let initialSnapshot = DiaryFormChangeSnapshot(
            date: date,
            breakfastRecipeIDs: ["recipe"],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: [],
            note: ""
        )
        let currentSnapshot = DiaryFormChangeSnapshot(
            date: date,
            breakfastRecipeIDs: [],
            lunchRecipeIDs: ["recipe"],
            dinnerRecipeIDs: [],
            note: ""
        )

        #expect(currentSnapshot != initialSnapshot)
    }
}
