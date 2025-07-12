//
//  SearchRecipesIntentTests.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/07/12.
//

@testable import Cookle
import Testing

struct SearchRecipesIntentTests {
    let context = testContext

    @Test func perform() throws {
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
                searchText: "Panc"
            )
        )
        #expect(result.count == 1)
        #expect(result.first?.name == "Pancakes")
    }
}
