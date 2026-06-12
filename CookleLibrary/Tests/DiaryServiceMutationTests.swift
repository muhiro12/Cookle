@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiaryServiceMutationTests {
    let context: ModelContext = makeTestContext()

    @Test
    func add_creates_new_diary_for_recipe_when_missing() throws {
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

        let diary = try DiaryService.add(
            context: context,
            date: .now,
            recipe: pancake,
            type: .breakfast
        )

        #expect(diary.note.isEmpty)
        #expect((diary.objects ?? []).count == 1)
        #expect((diary.objects ?? []).first?.recipe === pancake)
        #expect((diary.objects ?? []).first?.type == .breakfast)
    }

    @Test
    func add_appends_recipe_to_existing_diary() throws {
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
        let soup = Recipe.create(
            context: context,
            name: "Soup",
            photos: [],
            servingSize: 1,
            cookingTime: 20,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [pancake],
            lunches: [],
            dinners: [],
            note: "Keep note"
        )

        let updatedDiary = try DiaryService.add(
            context: context,
            date: diary.date,
            recipe: soup,
            type: .dinner
        )

        #expect(updatedDiary === diary)
        #expect(updatedDiary.note == "Keep note")
        #expect((updatedDiary.objects ?? []).count == 2)
        #expect((updatedDiary.objects ?? []).first { object in
            object.type == .breakfast
        }?.recipe === pancake)
        #expect((updatedDiary.objects ?? []).first { object in
            object.type == .dinner
        }?.recipe === soup)
    }

    @Test
    func create_creates_note_only_diary() throws {
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [],
            lunches: [],
            dinners: [],
            note: "Quick note"
        )

        let diaries = try context.fetch(.diaries(.all))
        #expect(diaries.first === diary)
        #expect((diary.objects ?? []).isEmpty)
        #expect(diary.note == "Quick note")
    }

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
    func update_updates_diary_with_new_note_and_recipe() {
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
    func update_allows_note_only_diary_and_clears_meals() {
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
        let diary = DiaryService.create(
            context: context,
            date: .now,
            breakfasts: [pancake],
            lunches: [],
            dinners: [],
            note: ""
        )

        DiaryService.update(
            context: context,
            diary: diary,
            date: diary.date,
            breakfasts: [],
            lunches: [],
            dinners: [],
            note: "Only note"
        )

        #expect((diary.objects ?? []).isEmpty)
        #expect((diary.recipes ?? []).isEmpty)
        #expect(diary.note == "Only note")
    }
}
