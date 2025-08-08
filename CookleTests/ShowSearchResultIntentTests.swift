//
//  ShowSearchResultIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Testing
import SwiftData

struct ShowSearchResultIntentTests {
    let context = testContext

    @Test func perform() throws {
        _ = Recipe.create(
            context: context,
            name: "Pancakes",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [
                .create(context: context, ingredient: "Egg", amount: "2", order: 1)
            ],
            steps: [],
            categories: [],
            note: ""
        )
        let category = Category.create(context: context, value: "Breakfast")
        _ = Recipe.create(
            context: context,
            name: "Toast",
            photos: [],
            servingSize: 1,
            cookingTime: 5,
            ingredients: [],
            steps: [],
            categories: [category],
            note: ""
        )

        let result = try ShowSearchResultIntent.perform(
            (
                context: context,
                text: "Egg"
            )
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }
}
