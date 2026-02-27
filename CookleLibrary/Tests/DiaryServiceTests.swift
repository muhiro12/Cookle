@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiaryServiceTests {
    let context: ModelContext = makeTestContext()

    @Test
    func create_creates_diary_with_breakfast_recipe() throws {
        let pancake = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [pancake],
            lunches: [],
            dinners: [],
            note: "Note"
        )

        let diaries = try context.fetch(.diaries(.all))
        #expect(diaries.first?.objects?.first?.recipe === pancake)
    }

    @Test
    func update_updates_diary_with_new_note_and_recipe() throws {
        let pancake = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let diary = Diary.create(
            context: context,
            date: .now,
            objects: [],
            note: ""
        )
        DiaryService.update(
            context: context,
            diary: diary,
            date: .now,
            breakfasts: [pancake],
            lunches: [],
            dinners: [],
            note: "Updated"
        )

        #expect(diary.note == "Updated")
        #expect(diary.objects?.first?.recipe === pancake)
    }

    @Test
    func latestDiary_returns_most_recent_diary() throws {
        let first = Diary.create(
            context: context,
            date: .now.addingTimeInterval(-86_400),
            objects: [],
            note: "first"
        )
        _ = Diary.create(
            context: context,
            date: .now,
            objects: [],
            note: "second"
        )
        first.update(
            date: .now.addingTimeInterval(86_400),
            objects: [],
            note: first.note
        )

        let result = try DiaryService.latestDiary(context: context)
        #expect(result === first)
    }

    @Test
    func randomDiary_returns_any_existing_diary() throws {
        _ = Diary.create(
            context: context,
            date: .now,
            objects: [],
            note: "one"
        )
        _ = Diary.create(
            context: context,
            date: .now.addingTimeInterval(86_400),
            objects: [],
            note: "two"
        )

        let result = try DiaryService.randomDiary(context: context)
        #expect(result != nil)
    }
}
