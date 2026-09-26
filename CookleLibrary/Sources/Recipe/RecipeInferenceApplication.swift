import Foundation

/// Recipe form input replaced by an inferred recipe, kept with the input it
/// replaced so the replacement can be undone once.
///
/// Applying another inference produces a new value whose previous input is
/// the form as it stood immediately before that application, so undo always
/// goes back exactly one application.
public struct RecipeInferenceApplication: Sendable {
    /// Form input immediately before the inferred values replaced it, including photos.
    public let previousInput: RecipeFormInput
    /// Form input produced by the application.
    public let appliedInput: RecipeFormInput

    private let appliedSnapshot: RecipeFormChangeSnapshot

    /// Replaces the inferable fields of `input` with `inference`.
    ///
    /// Photos are not inferred and stay as they are. Unknown numeric values
    /// become empty fields rather than a guessed number, and each list keeps
    /// its trailing blank row for further entry.
    init(
        inference: RecipeInferenceResult,
        sourceURL: URL?,
        replacing input: RecipeFormInput
    ) {
        let replacement = RecipeFormInput(
            name: inference.name,
            photos: input.photos,
            servingSize: Self.text(for: inference.servingSize),
            cookingTime: Self.text(for: inference.cookingTime),
            ingredients: inference.ingredients.map { ingredient in
                .init(
                    ingredient: ingredient.ingredient,
                    amount: ingredient.amount
                )
            } + [
                .init(
                    ingredient: "",
                    amount: ""
                )
            ],
            steps: inference.steps + [""],
            categories: inference.categories + [""],
            note: RecipeWebsiteImportOperations.note(
                inference.note,
                sourceURL: sourceURL
            )
        )
        previousInput = input
        appliedInput = replacement
        appliedSnapshot = .init(input: replacement)
    }

    /// Indicates whether applying an inference to `input` would replace
    /// something the user entered, so the replacement needs review first.
    ///
    /// Photos are ignored because an inference never replaces them.
    static func replacesEnteredValues(
        in input: RecipeFormInput
    ) -> Bool {
        let fields = [
            input.name,
            input.servingSize,
            input.cookingTime,
            input.note
        ]
        return fields.contains { field in
            isBlank(field) == false
        }
        || input.ingredients.contains { ingredient in
            isBlank(ingredient.ingredient) == false
                || isBlank(ingredient.amount) == false
        }
        || input.steps.contains { step in
            isBlank(step) == false
        }
        || input.categories.contains { category in
            isBlank(category) == false
        }
    }

    /// Indicates whether `currentInput` was edited after this application,
    /// meaning undo would also discard those later edits.
    public func hasEdits(
        in currentInput: RecipeFormInput
    ) -> Bool {
        RecipeFormChangeSnapshot(input: currentInput) != appliedSnapshot
    }
}

private extension RecipeInferenceApplication {
    static func text(
        for value: Int
    ) -> String {
        value == .zero ? "" : value.description
    }

    static func isBlank(
        _ value: String
    ) -> Bool {
        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .isEmpty
    }
}
