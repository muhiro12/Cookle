//
//  CreateDiaryIntentTests.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

@testable import Cookle
import Foundation
import SwiftData
import Testing

struct CreateDiaryIntentTests {
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
        _ = CreateDiaryIntent.perform(
            (
                context: context,
                date: .now,
                breakfasts: [pancake],
                lunches: [],
                dinners: [],
                note: "Note"
            )
        )

        let diaries = try context.fetch(.diaries(.all))
        #expect(diaries.first?.objects?.first?.recipe === pancake)
    }
}
