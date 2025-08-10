//
//  InferRecipeIntent.swift
//  Cookle
//
//  Created by Codex on 2025/07/09.
//

import AppIntents
import FoundationModels

@available(iOS 26.0, *)
@MainActor
struct InferRecipeIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource {
        .init("Infer Recipe")
    }

    @Parameter(title: "Recipe Text")
    private var text: String

    func perform() async throws -> some IntentResult {
        let result = try await RecipeService.infer(text: text)
        return .result(value: result)
    }
}
