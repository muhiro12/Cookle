import Foundation

extension RecipeFormModel {
    /// Indicates whether an inferred recipe would replace values entered in
    /// this form, so the replacement needs review first.
    var inferenceReplacesEnteredValues: Bool {
        RecipeFormOperations.inferenceReplacesEnteredValues(
            in: formInput
        )
    }

    /// Indicates whether the form changed after the latest inference was
    /// applied, so undoing it would also discard those changes.
    var hasEditsSinceInference: Bool {
        inferenceApplication?.hasEdits(
            in: formInput
        ) ?? false
    }

    /// Replaces the inferable fields with `inference`, keeping photos and the
    /// replaced input for one undo. Nothing is saved until the form is saved.
    func applyInference(
        _ inference: RecipeInferenceResult,
        sourceURL: URL?
    ) {
        let application = RecipeFormOperations.applyInference(
            inference,
            sourceURL: sourceURL,
            to: formInput
        )
        replaceInput(
            with: application.appliedInput
        )
        inferenceApplication = application
    }

    /// Restores the whole form, including photos, to its state immediately
    /// before the latest inference was applied.
    func undoInference() {
        guard let inferenceApplication else {
            return
        }

        replaceInput(
            with: inferenceApplication.previousInput
        )
        self.inferenceApplication = nil
    }
}

private extension RecipeFormModel {
    func replaceInput(
        with input: RecipeFormInput
    ) {
        name = input.name
        photos = input.photos
        servingSize = input.servingSize
        cookingTime = input.cookingTime
        ingredients = RecipeFormPlaceholderRows.normalizedIngredients(
            input.ingredients
        )
        steps = RecipeFormPlaceholderRows.normalizedStrings(
            input.steps
        )
        categories = RecipeFormPlaceholderRows.normalizedStrings(
            input.categories
        )
        note = input.note
    }
}
