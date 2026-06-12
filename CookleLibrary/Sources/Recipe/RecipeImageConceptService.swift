/// Internal Image Playground concept collaborator used by recipe Operations.
enum RecipeImageConceptService {
    private static let finishStepMarkers = [
        "serve",
        "served",
        "serving",
        "plate",
        "plated",
        "garnish",
        "finish",
        "finished",
        "finished with",
        "top with",
        "topped with",
        "drizzle",
        "sprinkle",
        "arrange",
        "盛り付け",
        "盛りつけ",
        "盛る",
        "盛って",
        "盛り",
        "仕上げ",
        "仕上がり",
        "仕上げる",
        "完成",
        "添える",
        "のせる",
        "のせて",
        "かける",
        "かけて",
        "トッピング",
        "飾る",
        "器に",
        "皿に"
    ]

    /// Returns a normalized concept draft for Image Playground generation.
    static func makeDraft(
        request: RecipeImageConceptRequest
    ) -> RecipeImageConceptDraft? {
        guard let title = normalizedText(from: request.name) else {
            return nil
        }

        let ingredients = request.ingredients.compactMap { ingredient in
            normalizedText(from: ingredient)
        }
        let finishSteps = request.steps
            .compactMap { step in
                normalizedText(from: step)
            }
            .filter { step in
                isFinishOrPlatingStep(step)
            }
        let combinedSteps = finishSteps.isEmpty
            ? nil
            : finishSteps.joined(separator: "\n")

        return .init(
            title: title,
            ingredients: ingredients,
            combinedSteps: combinedSteps
        )
    }

    static func normalizedText(from value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        let collapsedValue = RecipeBlurbService.collapsedWhitespace(trimmedValue)
        guard !collapsedValue.isEmpty else {
            return nil
        }
        return collapsedValue
    }

    static func isFinishOrPlatingStep(
        _ value: String
    ) -> Bool {
        let normalizedValue = value.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive,
                .widthInsensitive
            ],
            locale: .current
        )

        return finishStepMarkers.contains { marker in
            normalizedValue.localizedCaseInsensitiveContains(marker)
        }
    }
}
