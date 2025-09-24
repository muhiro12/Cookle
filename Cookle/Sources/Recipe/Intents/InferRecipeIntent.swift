//
//  InferRecipeIntent.swift
//  Cookle
//
//  Created by Codex on 2025/07/09.
//

import AppIntents
import FoundationModels

@available(iOS 26.0, *)
struct InferRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        .init("Infer Recipe")
    }

    @Parameter(title: "Recipe Text")
    private var text: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let inferred = try await RecipeService.infer(text: text)
        let entity = RecipeEntity(
            id: UUID().uuidString,
            name: inferred.name,
            photos: [],
            servingSize: inferred.servingSize,
            cookingTime: inferred.cookingTime,
            ingredients: inferred.ingredients.map { ($0.ingredient, $0.amount) },
            steps: inferred.steps,
            categories: inferred.categories,
            note: inferred.note,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        return .result(value: entity)
    }
}
