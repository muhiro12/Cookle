//
//  UpdateDiaryIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Foundation
import SwiftData
import Testing

struct UpdateDiaryIntentTests {
    let context = testContext

    @Test func perform() throws {
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
        UpdateDiaryIntent.perform(
            (
                context: context,
                diary: diary,
                date: .now,
                breakfasts: [pancake],
                lunches: [],
                dinners: [],
                note: "Updated"
            )
        )

        #expect(diary.note == "Updated")
        #expect(diary.objects?.first?.recipe === pancake)
    }
}
