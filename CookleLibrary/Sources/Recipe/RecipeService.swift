import Foundation
import FoundationModels
import SwiftData

/// Recipe-related domain services.
@preconcurrency
@MainActor
public enum RecipeService {
    /// Returns the last opened recipe stored in preferences, if available.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - lastOpenedRecipeID: Optional base64-encoded persistent identifier.
    /// - Returns: The matching `Recipe` or `nil` when not found.
    public static func lastOpenedRecipe(
        context: ModelContext,
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(for: .lastOpenedRecipeID)
            ?? CooklePreferences.string(for: .lastOpenedRecipeID)
    ) throws -> Recipe? {
        guard let lastOpenedRecipeID else {
            return nil
        }
        let id = try PersistentIdentifier(base64Encoded: lastOpenedRecipeID)
        return try context.fetchFirst(.recipes(.idIs(id)))
    }

    /// Returns any single recipe from the store.
    /// - Parameter context: Model context to query.
    /// - Returns: A random `Recipe` or `nil` when the store is empty.
    public static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try context.fetchRandom(.recipes(.all))
    }

    /// Returns the most recently updated recipe.
    public static func latestRecipe(context: ModelContext) throws -> Recipe? {
        let descriptor: FetchDescriptor<Recipe> = .init(
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse),
                .init(\.createdTimestamp, order: .reverse),
                .init(\.name)
            ]
        )
        return try context.fetch(descriptor).first
    }

    /// Searches recipes by a unified text condition that matches name, ingredients, or categories.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text. Short text (< 3 chars) uses equality for tags; otherwise partial match.
    /// - Returns: Matching recipes ordered by name.
    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
        try context.fetch(.recipes(.anyTextMatches(text)))
    }

    /// Deletes the supplied recipe from the store.
    public static func delete(
        context: ModelContext,
        recipe: Recipe
    ) {
        context.delete(recipe)
    }

    // LLM-based inference with a graceful heuristic fallback.
    /// Infers a recipe structure from free-form text using an LLM, with a heuristic fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: An `InferredRecipe` with best-effort fields filled.
    @available(iOS 26.0, *)
    public static func infer(text: String) async -> InferredRecipe {
        let languageName = inferredLanguageName()

        let instructions = """
            You are a professional chef and culinary expert running a recipe website.
            Kindly and thoroughly teach users how to prepare recipes.
            Make your explanations easy to follow and friendly for home cooks of any skill level.
            """
        let session = LanguageModelSession(instructions: instructions)

        let prompt = inferencePrompt(
            languageName: languageName,
            text: text
        )

        do {
            return try await session.respond(
                to: prompt,
                generating: InferredRecipe.self
            ).content
        } catch {
            return fallbackInference(from: text)
        }
    }
}

@available(iOS 26.0, *)
private extension RecipeService {
    static func inferredLanguageName() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: languageCode) ?? "English"
    }

    static func inferencePrompt(
        languageName: String,
        text: String
    ) -> String {
        """
        Analyze the following text and provide a recipe form. Please respond in \(languageName).
        """ + "\n" + text
    }

    static func fallbackInference(from text: String) -> InferredRecipe {
        let lines = text.split(separator: "\n").map(String.init)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = firstLine?.isEmpty == false ? firstLine ?? "Recipe" : "Recipe"
        let sourceText = lines.joined(separator: " ")

        return .init(
            name: name,
            servingSize: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(serves|for)\s*(\d+)"#
            ),
            cookingTime: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(\d+)\s*(min|minutes)"#
            ),
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    static func extractedNumber(
        in sourceText: String,
        pattern: String
    ) -> Int {
        guard let match = sourceText.range(
            of: pattern,
            options: .regularExpression
        ) else {
            return .zero
        }
        let matchedText = String(sourceText[match])
        let digits = matchedText
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return Int(digits) ?? .zero
    }
}
