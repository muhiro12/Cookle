//
//  CookleFoundationModel.swift
//  Cookle Playgrounds
//
//  Created by codex on 2025/06/30.
//

import FoundationModels
import SwiftUI

@available(iOS 26.0, *)
enum CookleFoundationModel {
    @Generable
    struct Ingredient {
        var ingredient: String
        var amount: String
    }

    @Generable
    struct Draft {
        var name: String
        var servingSize: String
        var cookingTime: String
        var ingredients: [Ingredient]
        var steps: [String]
        var note: String
    }

    static var isSupported: Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    static func summarizeRecipe(_ text: String) async throws -> RecipeDraft {
        let prompt = """
        Summarize the following OCR text into a recipe with the properties name, servingSize, cookingTime, ingredients, steps and note.

        \(text)
        """

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: prompt,
            generating: Draft.self
        )

        var draft = RecipeDraft()
        draft.name = response.content.name
        draft.servingSize = response.content.servingSize
        draft.cookingTime = response.content.cookingTime
        draft.ingredients = response.content.ingredients.map { ($0.ingredient, $0.amount) }
        draft.steps = response.content.steps
        draft.note = response.content.note
        return draft
    }
}
