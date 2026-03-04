import Foundation

/// Input used to build Image Playground concepts from recipe content.
public struct RecipeImageConceptRequest: Sendable {
    public let name: String
    public let ingredients: [String]
    public let steps: [String]

    public init(
        name: String,
        ingredients: [String],
        steps: [String]
    ) {
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
    }
}

/// Normalized recipe content passed into Image Playground.
public struct RecipeImageConceptDraft: Sendable {
    public let title: String
    public let ingredients: [String]
    public let combinedSteps: String?

    public init(
        title: String,
        ingredients: [String],
        combinedSteps: String?
    ) {
        self.title = title
        self.ingredients = ingredients
        self.combinedSteps = combinedSteps
    }
}

/// Builds Image Playground concept input from saved recipe content.
public enum RecipeImageConceptService {
    public static func makeDraft(
        request: RecipeImageConceptRequest
    ) -> RecipeImageConceptDraft? {
        guard let title = normalizedText(from: request.name) else {
            return nil
        }

        let ingredients = request.ingredients.compactMap { ingredient in
            normalizedText(from: ingredient)
        }
        let normalizedSteps = request.steps.compactMap { step in
            normalizedText(from: step)
        }
        let combinedSteps = normalizedSteps.isEmpty
            ? nil
            : normalizedSteps.joined(separator: "\n")

        return .init(
            title: title,
            ingredients: ingredients,
            combinedSteps: combinedSteps
        )
    }
}

extension RecipeImageConceptService {
    static func normalizedText(from value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isNotEmpty else {
            return nil
        }

        let collapsedValue = RecipeBlurbService.collapsedWhitespace(trimmedValue)
        guard collapsedValue.isNotEmpty else {
            return nil
        }
        return collapsedValue
    }
}
