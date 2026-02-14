import Foundation
import FoundationModels
import SwiftData

/// Recipe-related domain services.
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

    /// Searches recipes by a unified text condition that matches name, ingredients, or categories.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text. Short text (< 3 chars) uses equality for tags; otherwise partial match.
    /// - Returns: Matching recipes ordered by name.
    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
        try context.fetch(.recipes(.anyTextMatches(text)))
    }

    // LLM-based inference with a graceful heuristic fallback.
    /// Infers a recipe structure from free-form text using an LLM, with a heuristic fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: An `InferredRecipe` with best-effort fields filled.
    @available(iOS 26.0, *)
    public static func infer(text: String) async throws -> InferredRecipe {
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

        do {
            return try await session.respond(
                to: prompt,
                generating: InferredRecipe.self
            ).content
        } catch {
            // Heuristic fallback: extract name from first line, simple numbers for serving/time.
            let lines = text.split(separator: "\n").map(String.init)
            let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (first?.isEmpty == false) ? first! : "Recipe"

            let servingSize: Int = {
                let pattern = #"(?i)(serves|for)\s*(\d+)"#
                if let match = lines.joined(separator: " ").range(of: pattern, options: .regularExpression) {
                    let s = String(lines.joined(separator: " ")[match])
                    if let n = Int(s.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) { return n }
                }
                return 0
            }()

            let cookingTime: Int = {
                let pattern = #"(?i)(\d+)\s*(min|minutes)"#
                if let match = lines.joined(separator: " ").range(of: pattern, options: .regularExpression) {
                    let s = String(lines.joined(separator: " ")[match])
                    if let n = Int(s.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) { return n }
                }
                return 0
            }()

            return InferredRecipe(
                name: name,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        }
    }
}
