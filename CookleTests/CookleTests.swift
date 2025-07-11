//
//  CookleTests.swift
//  CookleTests
//
//  Created by Hiromu Nakano on 2025/06/20.
//

import SwiftData
import Testing

@testable import Cookle
internal import Foundation

@MainActor
struct CookleTests {
    @Test func recipeSearch() throws {
        let container = try ModelContainer(
            for: Recipe.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        _ = Recipe.create(
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
        _ = Recipe.create(
            context: context,
            name: "Spaghetti",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let result = try SearchRecipesIntent.perform(
            (
                context: context,
                text: "Panc"
            )
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }

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
