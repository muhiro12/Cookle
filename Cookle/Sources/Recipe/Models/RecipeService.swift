import Foundation
import FoundationModels
import SwiftData
import SwiftUI

@MainActor
enum RecipeService {
    static func lastOpenedRecipe(context: ModelContext) throws -> Recipe? {
        guard let lastOpenedRecipeID = AppStorage(.lastOpenedRecipeID).wrappedValue else {
            return nil
        }
        let id = try PersistentIdentifier(base64Encoded: lastOpenedRecipeID)
        return try context.fetchFirst(.recipes(.idIs(id)))
    }

    static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try context.fetchRandom(.recipes(.all))
    }

    static func search(context: ModelContext, text: String) throws -> [Recipe] {
        var recipes = try context.fetch(
            .recipes(.nameContains(text))
        )
        let ingredients = try context.fetch(
            text.count < 3
                ? .ingredients(.valueIs(text))
                : .ingredients(.valueContains(text))
        )
        let categories = try context.fetch(
            text.count < 3
                ? .categories(.valueIs(text))
                : .categories(.valueContains(text))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        return Array(Set(recipes))
    }

    @available(iOS 26.0, *)
    static func infer(text: String) async throws -> RecipeEntity {
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
            """ + "\n" + text
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
}
