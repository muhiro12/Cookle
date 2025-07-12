//
//  InferRecipeIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Testing

struct InferRecipeIntentTests {
    @Test func perform() async throws {
        let result = try await InferRecipeIntent.perform("Pancake recipe")
        #expect(!result.name.isEmpty)
    }
}
