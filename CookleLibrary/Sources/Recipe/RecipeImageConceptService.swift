/// Builds Image Playground concept input from saved recipe content.
public enum RecipeImageConceptService {
    /// Returns a normalized concept draft for Image Playground generation.
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
