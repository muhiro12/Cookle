import Foundation

/// Shared rules for turning creative output into an editable recipe draft.
@preconcurrency
@MainActor
public enum RecipeGenerationOperations {
    /// A directly observable omission in generated fields, not a culinary judgment.
    public enum DraftIssue: Equatable, Sendable {
        /// The dish name is empty.
        case missingName
        /// No ingredient rows were provided.
        case missingIngredients
        /// An ingredient row has no name.
        case missingIngredientName(row: Int)
        /// An ingredient row has no quantity.
        case missingIngredientAmount(row: Int)
        /// No usable cooking steps were provided.
        case missingSteps
        /// The serving count is not positive.
        case invalidServingSize
        /// The duration is negative.
        case invalidCookingTime

        /// A specific finding to pass to the model as application feedback.
        public var repairInstruction: String {
            switch self {
            case .missingName:
                "The dish name is empty. Provide a concise dish name."
            case .missingIngredients:
                "The ingredient list is empty. List the ingredients and quantities used in the steps."
            case .missingIngredientName(let row):
                "Ingredient row \(row) has no name. Identify the ingredient used in the recipe."
            case .missingIngredientAmount(let row):
                "Ingredient row \(row) has no quantity. Supply a practical quantity for the requested servings."
            case .missingSteps:
                "There are no usable cooking steps. Provide the complete ordered preparation and cooking steps."
            case .invalidServingSize:
                "The serving count is not positive. Follow the requested servings, or choose a household portion."
            case .invalidCookingTime:
                "The total preparation and cooking duration is negative. Provide a nonnegative duration in minutes."
            }
        }
    }

    /// Generates a recipe with Private Cloud Compute without substituting another model.
    ///
    /// Unavailability and failed requests leave the input available for an explicit retry.
    /// Cancellation takes precedence over a late response or service error.
    public static func generate(
        unavailableReason: RecipeGenerationError?,
        generateWithCloud: () async throws -> RecipeInferenceResult,
        onStatus: (RecipeGenerationStatus) -> Void
    ) async throws -> RecipeInferenceResult {
        try Task.checkCancellation()
        if let unavailableReason {
            throw unavailableReason
        }

        onStatus(.privateCloudCompute)
        try Task.checkCancellation()
        do {
            let recipe = try await generateWithCloud()
            try Task.checkCancellation()
            return recipe
        } catch {
            try Task.checkCancellation()
            throw error
        }
    }

    /// Normalizes creative output and requires a name, ingredients, and steps.
    ///
    /// Unlike extraction, generated quantities and instructions need not appear
    /// in the request. This checks usable structure, not culinary correctness.
    public static func preparedDraft(
        from generated: RecipeInferenceResult
    ) -> RecipeInferenceResult? {
        var draft = RecipeInferenceOperations.sanitizedInference(generated)
        // The editor supplies row numbers. Strip generated list markers while
        // preserving quantities such as "1.5 tbsp" at the start of a step.
        draft.steps = stepsWithoutListMarkers(draft.steps)
        guard !draft.name.isEmpty,
              !draft.ingredients.isEmpty,
              !draft.steps.isEmpty else {
            return nil
        }
        return draft
    }

    /// Finds missing fields without inferring taste, dietary intent, or ingredient aliases.
    public static func draftIssues(in generated: RecipeInferenceResult) -> [DraftIssue] {
        var issues = [DraftIssue]()
        if generated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingName)
        }
        if generated.servingSize < 1 {
            issues.append(.invalidServingSize)
        }
        if generated.cookingTime < 0 {
            issues.append(.invalidCookingTime)
        }
        if generated.ingredients.isEmpty {
            issues.append(.missingIngredients)
        }
        for (index, ingredient) in generated.ingredients.enumerated() {
            if ingredient.ingredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.missingIngredientName(row: index + 1))
            }
            if ingredient.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.missingIngredientAmount(row: index + 1))
            }
        }
        let normalized = RecipeInferenceOperations.sanitizedInference(generated)
        if stepsWithoutListMarkers(normalized.steps).isEmpty {
            issues.append(.missingSteps)
        }
        return issues
    }

    /// Repairs observable field omissions at most once, then checks the complete result again.
    ///
    /// Service errors propagate without retry. Cancellation discards a late repair.
    /// A returned draft has usable fields; its culinary correctness is not established.
    public static func validatedDraft(
        from generated: RecipeInferenceResult,
        repair: (RecipeInferenceResult, [DraftIssue]) async throws -> RecipeInferenceResult
    ) async throws -> RecipeInferenceResult? {
        try Task.checkCancellation()
        let issues = draftIssues(in: generated)
        if issues.isEmpty {
            return preparedDraft(from: generated)
        }
        let repaired: RecipeInferenceResult
        do {
            repaired = try await repair(generated, issues)
            try Task.checkCancellation()
        } catch {
            try Task.checkCancellation()
            throw error
        }
        guard draftIssues(in: repaired).isEmpty else {
            return nil
        }
        return preparedDraft(from: repaired)
    }

    private static func stepsWithoutListMarkers(_ steps: [String]) -> [String] {
        steps
            .map { step in
                step.replacingOccurrences(
                    of: #"^(?:[0-9０-９]+[.．)）]|[-*•])(?:\s+|$)"#,
                    with: "",
                    options: .regularExpression
                )
            }
            .filter { step in
                !step.isEmpty
            }
    }
}
