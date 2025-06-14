//
//  CookleFoundationModel.swift
//  Cookle Playgrounds
//
//  Created by codex on 2025/06/30.
//

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

enum CookleFoundationModel {
    static var isSupported: Bool {
        if #available(iOS 19.0, *) {
#if canImport(FoundationModels)
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
#else
            return false
#endif
        } else {
            return false
        }
    }


    @available(iOS 19.0, *)
    static func summarizeRecipe(_ text: String) async throws -> RecipeDraft {
#if canImport(FoundationModels)
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
#else
        throw OCRRecipeBuilder.OCRRecipeBuilderError.unsupported
#endif
    }
}
