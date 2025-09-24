import Foundation
import FoundationModels
import SwiftData

@MainActor
public enum RecipeService {
    public static func lastOpenedRecipe(
        context: ModelContext,
        lastOpenedRecipeID: String? = CooklePreferences.string(for: .lastOpenedRecipeID)
    ) throws -> Recipe? {
        guard let lastOpenedRecipeID else {
            return nil
        }
        let id = try PersistentIdentifier(base64Encoded: lastOpenedRecipeID)
        return try context.fetchFirst(.recipes(.idIs(id)))
    }

    public static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try context.fetchRandom(.recipes(.all))
    }

    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
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

    // LLM-based inference with a graceful heuristic fallback.
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
