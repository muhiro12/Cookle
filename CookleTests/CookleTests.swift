//
//  CookleTests.swift
//  CookleTests
//
//  Created by Hiromu Nakano on 2025/06/20.
//

@testable import Cookle
import Foundation
import SwiftData
import Testing

var testContext: ModelContext {
    let schema = Schema([Recipe.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return .init(
        try! .init(for: schema, configurations: [configuration])
    )
}

@MainActor
struct CookleTests {
    @Test func diaryCreate() throws {
        let container = try ModelContainer(
            for: Recipe.self, Diary.self, DiaryObject.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
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
