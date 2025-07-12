//
//  ShowRandomRecipeIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Testing
import SwiftData

struct ShowRandomRecipeIntentTests {
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

        let result = try ShowRandomRecipeIntent.perform(context)
        #expect(result != nil)
        #expect(result === pancake || result?.name == "Spaghetti")
    }
}
