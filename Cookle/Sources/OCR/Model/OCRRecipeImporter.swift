//
//  OCRRecipeImporter.swift
//  Cookle
//
//  Created by Codex on 2025/06/07.
//

import SwiftData

enum OCRRecipeImporter {
    static func createRecipe(context: ModelContext, from data: Data) throws -> Recipe {
        let strings = try PhotoOCR.recognize(from: data)
        let text = strings.joined(separator: "\n")
        let parsed = RecipeTextParser.parse(text)
        return Recipe.create(
            context: context,
            name: parsed.name,
            photos: [],
            servingSize: .zero,
            cookingTime: .zero,
            ingredients: parsed.ingredients.enumerated().map { index, element in
                .create(context: context,
                        ingredient: element.ingredient,
                        amount: element.amount,
                        order: index + 1)
            },
            steps: parsed.steps,
            categories: [],
            note: ""
        )
    }
}
