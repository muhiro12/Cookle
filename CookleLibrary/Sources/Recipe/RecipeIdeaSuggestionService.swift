import Foundation
import FoundationModels

/// Builds lightweight dish ideas from selected ingredients without saving generated content.
@available(iOS 26.0, *)
public enum RecipeIdeaSuggestionService {
    private enum Constants {
        static let maxInputIngredients = 8
        static let maxSuggestions = 4
        static let maxCoreIngredients = 4
        static let pairedIngredientCount = 2
        static let bowlIngredientCount = 3
    }

    static var suggestionInstructions: String {
        """
        You suggest lightweight dish ideas from ingredients the user already has.
        Do not generate a full recipe.
        Do not provide exact measurements, full step-by-step instructions, or food safety guarantees.
        Keep the output inspirational and non-authoritative.
        Prefer ideas that use multiple selected ingredients together.
        Do not invent ingredients outside the selected ingredient list as core ingredients.
        Preserve the user's language when practical.
        """
    }

    /// Suggests lightweight dish ideas from the supplied ingredient names.
    public static func suggest(
        ingredients: [String]
    ) async throws -> [RecipeIdeaSuggestion] {
        let normalizedIngredients = normalizedIngredients(
            ingredients
        )
        guard normalizedIngredients.isNotEmpty else {
            throw RecipeIdeaSuggestionError.emptyIngredients
        }

        let fallbackSuggestions = fallbackSuggestions(
            ingredients: normalizedIngredients
        )
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable:
            return fallbackSuggestions
        }

        let session = LanguageModelSession(
            instructions: suggestionInstructions
        )

        do {
            let response = try await session.respond(
                to: suggestionPrompt(
                    ingredients: normalizedIngredients
                ),
                generating: RecipeIdeaSuggestionResponse.self
            ).content
            let suggestions = sanitizedSuggestions(
                response.ideas,
                inputIngredients: normalizedIngredients
            )
            if suggestions.isNotEmpty {
                return suggestions
            }
        } catch {
            // Deterministic fallback keeps this feature useful when generation fails.
        }

        guard fallbackSuggestions.isNotEmpty else {
            throw RecipeIdeaSuggestionError.insufficientContent
        }
        return fallbackSuggestions
    }
}

@available(iOS 26.0, *)
extension RecipeIdeaSuggestionService {
    static func suggestionPrompt(
        ingredients: [String]
    ) -> String {
        """
        Suggest dish ideas from these selected ingredients.
        Return only the structured fields defined by the schema.

        Ingredients:
        \(ingredients.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    static func normalizedIngredients(
        _ ingredients: [String]
    ) -> [String] {
        var seenKeys = Set<String>()
        var result = [String]()

        for ingredient in ingredients {
            guard let normalizedIngredient = normalizedText(
                ingredient
            ) else {
                continue
            }
            let key = duplicateKey(
                normalizedIngredient
            )
            guard seenKeys.insert(key).inserted else {
                continue
            }
            result.append(normalizedIngredient)
            if result.count == Constants.maxInputIngredients {
                break
            }
        }

        return result
    }

    static func sanitizedSuggestions(
        _ suggestions: [RecipeIdeaSuggestion],
        inputIngredients: [String]
    ) -> [RecipeIdeaSuggestion] {
        var seenTitles = Set<String>()
        var result = [RecipeIdeaSuggestion]()

        for suggestion in suggestions {
            guard let title = normalizedText(suggestion.title) else {
                continue
            }
            let titleKey = duplicateKey(title)
            guard seenTitles.insert(titleKey).inserted else {
                continue
            }
            result.append(
                .init(
                    title: title,
                    flavorDirection: normalizedText(suggestion.flavorDirection) ?? .empty,
                    roughApproach: normalizedText(suggestion.roughApproach) ?? .empty,
                    coreIngredients: sanitizedCoreIngredients(
                        suggestion.coreIngredients,
                        inputIngredients: inputIngredients
                    )
                )
            )
            if result.count == Constants.maxSuggestions {
                break
            }
        }

        return result
    }

    static func fallbackSuggestions(
        ingredients: [String]
    ) -> [RecipeIdeaSuggestion] {
        guard let primaryIngredient = ingredients.first else {
            return []
        }

        var suggestions = [
            RecipeIdeaSuggestion(
                title: "\(primaryIngredient) skillet idea",
                flavorDirection: "Simple savory direction",
                roughApproach: """
                Use \(primaryIngredient) as the main focus, then finish with pantry seasoning and something bright.
                """,
                coreIngredients: [primaryIngredient]
            )
        ]

        if ingredients.count >= Constants.pairedIngredientCount {
            suggestions.append(
                pairedSuggestion(
                    ingredients: ingredients
                )
            )
        }

        if ingredients.count >= Constants.bowlIngredientCount {
            suggestions.append(
                pantryBowlSuggestion(
                    ingredients: ingredients
                )
            )
        }

        return Array(
            suggestions.prefix(Constants.maxSuggestions)
        )
    }
}

@available(iOS 26.0, *)
private extension RecipeIdeaSuggestionService {
    static func pairedSuggestion(
        ingredients: [String]
    ) -> RecipeIdeaSuggestion {
        let coreIngredients = Array(
            ingredients.prefix(Constants.pairedIngredientCount)
        )
        return .init(
            title: "\(coreIngredients[0]) and \(coreIngredients[1]) plate",
            flavorDirection: "Balanced main or side",
            roughApproach: """
            Cook the two ingredients together or separately, then connect them with a sauce, oil, or fresh garnish.
            """,
            coreIngredients: coreIngredients
        )
    }

    static func pantryBowlSuggestion(
        ingredients: [String]
    ) -> RecipeIdeaSuggestion {
        let coreIngredients = Array(
            ingredients.prefix(Constants.bowlIngredientCount)
        )
        return .init(
            title: "\(coreIngredients[0]) bowl direction",
            flavorDirection: "Flexible bowl-style meal",
            roughApproach: """
            Build a bowl around the selected ingredients and adjust the texture with something crisp, creamy, or acidic.
            """,
            coreIngredients: coreIngredients
        )
    }

    static func sanitizedCoreIngredients(
        _ ingredients: [String],
        inputIngredients: [String]
    ) -> [String] {
        let inputByKey = Dictionary(
            uniqueKeysWithValues: inputIngredients.map { ingredient in
                (
                    duplicateKey(ingredient),
                    ingredient
                )
            }
        )
        var seenKeys = Set<String>()
        var result = [String]()

        for ingredient in ingredients {
            guard let normalizedIngredient = normalizedText(
                ingredient
            ) else {
                continue
            }
            let key = duplicateKey(
                normalizedIngredient
            )
            guard let inputIngredient = inputByKey[key] else {
                continue
            }
            guard seenKeys.insert(key).inserted else {
                continue
            }
            result.append(inputIngredient)
            if result.count == Constants.maxCoreIngredients {
                break
            }
        }

        if result.isEmpty {
            return Array(
                inputIngredients.prefix(Constants.maxCoreIngredients)
            )
        }
        return result
    }

    static func normalizedText(
        _ value: String
    ) -> String? {
        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard trimmedValue.isNotEmpty else {
            return nil
        }
        return RecipeBlurbService.collapsedWhitespace(
            RecipeBlurbService.strippingListPrefix(
                from: trimmedValue
            )
        )
    }

    static func duplicateKey(
        _ value: String
    ) -> String {
        value.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive,
                .widthInsensitive
            ],
            locale: .current
        )
    }
}
