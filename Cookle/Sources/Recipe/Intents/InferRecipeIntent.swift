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
struct InferRecipeIntent: AppIntent, IntentPerformer {
    typealias Input = String
    typealias Output = RecipeEntity

    nonisolated static var title: LocalizedStringResource {
        .init("Infer Recipe")
    }

    @Parameter(title: "Recipe Text")
    private var text: String

    static func perform(_ input: Input) async throws -> Output {
        try await RecipeService.infer(text: input)
    }

    func perform() async throws -> some IntentResult {
        let result = try await Self.perform(text)
        return .result(value: result)
    }
}
