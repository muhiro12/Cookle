//
//  InferRecipeIntent.swift
//  Cookle
//
//  Created by Codex on 2025/07/09.
//

import AppIntents
import FoundationModels
import SwiftUtilities

@available(iOS 26.0, *)
struct InferRecipeIntent: AppIntent, IntentPerformer {
    static var title: LocalizedStringResource {
        .init("Infer Recipe")
    }

    @Parameter(title: "Recipe Text")
    private var text: String

    typealias Input = String
    typealias Output = RecipeEntity

    static func perform(_ input: Input) async throws -> Output {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let locale = Locale.current
        let languageName = locale.localizedString(forLanguageCode: languageCode) ?? "English"

        let instructions = """
            You are a professional chef and culinary expert running a recipe website.
            Kindly and thoroughly teach users how to prepare recipes, making your explanations easy to follow and friendly for home cooks of any skill level.
            """
        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
            Analyze the following text and provide a recipe form. Please respond in \(languageName).
            """ + "\n" + input
        let inferred = try await session.respond(
            to: prompt,
            generating: InferredRecipe.self
        ).content

        return .init(
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
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let result = try await Self.perform(text)
        return .result(value: result)
    }
}
