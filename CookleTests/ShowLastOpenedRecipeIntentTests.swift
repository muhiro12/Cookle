//
//  ShowLastOpenedRecipeIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Testing
import SwiftData
import SwiftUI

struct ShowLastOpenedRecipeIntentTests {
    let context = testContext

    @Test func perform() throws {
        let recipe = Recipe.create(
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
        let encoded = try recipe.id.base64Encoded()
        AppStorage(.lastOpenedRecipeID).wrappedValue = encoded

        let result = try ShowLastOpenedRecipeIntent.perform(context)
        #expect(result === recipe)
    }
}
