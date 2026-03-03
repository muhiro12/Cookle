import Foundation
import FoundationModels
import SwiftData

struct IngredientRecipeGenerationInput: Sendable {
    let availableIngredients: [String]
    let additionalInstructions: String
}

enum IngredientRecipeGenerationValidationError: Error, Equatable {
    case emptyIngredients
    case invalidResponse
    case disallowedIngredients([String])
}

@available(iOS 26.0, *)
@Generable
private struct IngredientRecipeGenerationToolArguments {}

@available(iOS 26.0, *)
@Generable
private struct AvailableIngredientsToolOutput {
    private(set) var ingredients: [String]
}

@available(iOS 26.0, *)
@Generable
private struct UserPreferencesToolOutput {
    private(set) var additionalInstructions: String
}

@available(iOS 26.0, *)
private struct GetAvailableIngredientsTool: Tool {
    let availableIngredients: [String]

    var name: String {
        "getAvailableIngredients"
    }

    var description: String {
        "Returns the exact ingredients that are currently available to the user."
    }

    func call(arguments _: IngredientRecipeGenerationToolArguments) -> AvailableIngredientsToolOutput {
        .init(ingredients: availableIngredients)
    }
}

@available(iOS 26.0, *)
private struct GetUserPreferencesTool: Tool {
    let additionalInstructions: String

    var name: String {
        "getUserPreferences"
    }

    var description: String {
        "Returns the user's optional one-shot cooking preferences or constraints."
    }

    func call(arguments _: IngredientRecipeGenerationToolArguments) -> UserPreferencesToolOutput {
        .init(additionalInstructions: additionalInstructions)
    }
}

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

    static func ingredientRecipeGenerationInput(
        availableIngredients: [String],
        additionalInstructions: String
    ) throws -> IngredientRecipeGenerationInput {
        let normalizedIngredients = normalizedIngredientDisplayValues(from: availableIngredients)
        guard normalizedIngredients.isNotEmpty else {
            throw IngredientRecipeGenerationValidationError.emptyIngredients
        }

        return .init(
            availableIngredients: normalizedIngredients,
            additionalInstructions: additionalInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    static func normalizedIngredientDisplayValues(from values: [String]) -> [String] {
        var seenNormalizedValues = Set<String>()
        var normalizedValues = [String]()

        for value in values {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedValue.isNotEmpty else {
                continue
            }

            let normalizedKey = normalizedIngredientKey(trimmedValue)
            guard seenNormalizedValues.insert(normalizedKey).inserted else {
                continue
            }

            normalizedValues.append(trimmedValue)
        }

        return normalizedValues
    }

    static func validateIngredientRecipeContent(
        name: String,
        steps: [String],
        generatedIngredients: [String],
        allowedIngredients: [String]
    ) throws {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            throw IngredientRecipeGenerationValidationError.invalidResponse
        }

        let normalizedSteps = steps.compactMap { step in
            let trimmedStep = step.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedStep.isNotEmpty ? trimmedStep : nil
        }
        guard normalizedSteps.isNotEmpty else {
            throw IngredientRecipeGenerationValidationError.invalidResponse
        }

        let allowedNormalizedIngredients = Set(
            normalizedIngredientDisplayValues(from: allowedIngredients).map(normalizedIngredientKey)
        )
        let disallowedIngredients = normalizedIngredientDisplayValues(from: generatedIngredients).filter { ingredient in
            !allowedNormalizedIngredients.contains(
                normalizedIngredientKey(ingredient)
            )
        }
        guard disallowedIngredients.isEmpty else {
            throw IngredientRecipeGenerationValidationError.disallowedIngredients(disallowedIngredients)
        }
    }

    // LLM-based inference with a graceful heuristic fallback.
    /// Infers a recipe structure from free-form text using an LLM, with a heuristic fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: An `InferredRecipe` with best-effort fields filled.
    @available(iOS 26.0, *)
    public static func infer(text: String) async -> InferredRecipe {
        let languageName = currentLanguageName()

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
                    let matchedText = String(lines.joined(separator: " ")[match])
                    if let servingSizeValue = Int(matchedText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        return servingSizeValue
                    }
                }
                return 0
            }()

            let cookingTime: Int = {
                let pattern = #"(?i)(\d+)\s*(min|minutes)"#
                if let match = lines.joined(separator: " ").range(of: pattern, options: .regularExpression) {
                    let matchedText = String(lines.joined(separator: " ")[match])
                    if let cookingTimeValue = Int(matchedText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        return cookingTimeValue
                    }
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

    /// Generates a recipe draft from selected ingredients using the on-device model.
    @available(iOS 26.0, *)
    public static func generateFromIngredients(
        request: IngredientRecipeGenerationRequest
    ) async throws -> InferredRecipe {
        let input: IngredientRecipeGenerationInput
        do {
            input = try ingredientRecipeGenerationInput(
                availableIngredients: request.availableIngredients,
                additionalInstructions: request.additionalInstructions
            )
        } catch let validationError as IngredientRecipeGenerationValidationError {
            throw IngredientRecipeGenerationError(validationError: validationError)
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw IngredientRecipeGenerationError.modelUnavailable(reason)
        }

        let languageName = currentLanguageName()
        let tools: [any Tool] = [
            GetAvailableIngredientsTool(
                availableIngredients: input.availableIngredients
            ),
            GetUserPreferencesTool(
                additionalInstructions: input.additionalInstructions
            )
        ]
        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: ingredientRecipeGenerationInstructions(
                languageName: languageName
            )
        )

        let inference: InferredRecipe
        do {
            inference = try await session.respond(
                to: ingredientRecipeGenerationPrompt(
                    languageName: languageName
                ),
                generating: InferredRecipe.self
            ).content
        } catch {
            throw IngredientRecipeGenerationError.invalidResponse
        }

        do {
            try validateIngredientRecipeContent(
                name: inference.name,
                steps: inference.steps,
                generatedIngredients: inference.ingredients.map(\.ingredient),
                allowedIngredients: input.availableIngredients
            )
        } catch let validationError as IngredientRecipeGenerationValidationError {
            throw IngredientRecipeGenerationError(validationError: validationError)
        }

        return inference
    }
}

private extension RecipeService {
    static func currentLanguageName() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: languageCode) ?? "English"
    }

    static func ingredientRecipeGenerationInstructions(
        languageName: String
    ) -> String {
        """
        You are a cautious home-cooking assistant.
        Always call getAvailableIngredients and getUserPreferences before generating a recipe.
        Return exactly one concise recipe in \(languageName).
        Keep the result practical for a home cook, with short clear steps and realistic quantities.
        Only use ingredients returned by getAvailableIngredients. Never introduce any other ingredients.
        Respect any optional constraints returned by getUserPreferences.
        Avoid unsafe, vague, or hazardous instructions.
        """
    }

    static func ingredientRecipeGenerationPrompt(
        languageName: String
    ) -> String {
        """
        Create one concise recipe draft in \(languageName).
        Call the ingredient and preference tools before responding.
        Return only the structured recipe fields in the provided schema.
        """
    }

    static func normalizedIngredientKey(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let halfwidthValue = trimmedValue.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? trimmedValue
        let katakanaValue = halfwidthValue.applyingTransform(
            .hiraganaToKatakana,
            reverse: false
        ) ?? halfwidthValue

        return katakanaValue.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive,
                .widthInsensitive
            ],
            locale: .current
        )
    }
}

@available(iOS 26.0, *)
private extension IngredientRecipeGenerationError {
    init(validationError: IngredientRecipeGenerationValidationError) {
        switch validationError {
        case .emptyIngredients:
            self = .emptyIngredients
        case .invalidResponse:
            self = .invalidResponse
        case .disallowedIngredients(let ingredients):
            self = .disallowedIngredients(ingredients)
        }
    }
}
