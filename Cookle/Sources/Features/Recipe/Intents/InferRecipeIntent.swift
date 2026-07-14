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
        let inferred = try await RecipeFoundationModelInferenceOperations.infer(text: text)
        let entity = InferredRecipeEntity(inferred)
        return .result(value: entity)
    }
}
