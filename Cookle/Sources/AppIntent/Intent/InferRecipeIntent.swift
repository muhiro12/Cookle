//
//  InferRecipeIntent.swift
//  Cookle
//
//  Created by Codex on 2025/07/09.
//

import AppIntents
import FoundationModels

@available(iOS 26.0, *)
struct InferRecipeIntent: AppIntent, IntentPerformer {
    static var title: LocalizedStringResource {
        .init("Infer Recipe")
    }

    @Parameter(title: "Recipe Text")
    private var text: String

    typealias Input = String
    typealias Output = RecipeEntity

    @MainActor
    static func inference(_ input: Input) async throws -> InferredRecipeForm {
        let session = LanguageModelSession()
        let prompt = """
            Analyze the following text and provide a recipe form.
            """ + "\n" + input
        let response = try await session.respond(
            to: prompt,
            generating: InferredRecipeForm.self
        )
        return response.content
    }

    static func perform(_ input: Input) async throws -> Output {
        let inferred = try await inference(input)
        return .init(
            id: UUID().uuidString,
            name: inferred.name,
            photos: [],
            servingSize: inferred.servingSize,
            cookingTime: inferred.cookingTime,
            ingredients: inferred.ingredients.map(\.ingredient),
            steps: inferred.steps,
            categories: inferred.categories,
            note: inferred.note,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let result = try await Self.perform(text)
        return .result(value: result)
    }
}
