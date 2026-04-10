import CookleLibrary
import MHPlatform

enum RecipeDraftLogging {
    enum Source: String {
        case formCreate = "form_create"
        case formEdit = "form_edit"
        case intentCreate = "intent_create"
        case intentUpdate = "intent_update"
    }

    struct Summary: Equatable {
        let source: Source
        let inputIngredientCount: Int
        let inputStepCount: Int
        let inputCategoryCount: Int
        let hasNote: Bool

        private var baseMetadata: [String: String] {
            [
                "source": source.rawValue,
                "input_ingredient_count": inputIngredientCount.description,
                "input_step_count": inputStepCount.description,
                "input_category_count": inputCategoryCount.description,
                "has_note": hasNote.description
            ]
        }

        func successMetadata(
            draft: RecipeFormDraft
        ) -> [String: String] {
            var metadata = baseMetadata
            metadata["draft_ingredient_count"] = draft.ingredients.count.description
            metadata["draft_step_count"] = draft.steps.count.description
            metadata["draft_category_count"] = draft.categories.count.description
            return metadata
        }

        func failureMetadata(
            error: Error
        ) -> [String: String] {
            var metadata = baseMetadata
            metadata["error_type"] = String(
                describing: type(of: error)
            )
            return metadata
        }
    }

    static func formSummary(
        type: RecipeFormType,
        ingredients: [RecipeFormIngredient],
        steps: [String],
        categories: [String],
        note: String
    ) -> Summary {
        .init(
            source: formSource(for: type),
            inputIngredientCount: ingredients.filter(\.ingredient.isNotEmpty).count,
            inputStepCount: steps.filter(\.isNotEmpty).count,
            inputCategoryCount: categories.filter(\.isNotEmpty).count,
            hasNote: note.isNotEmpty
        )
    }

    static func intentSummary(
        source: Source,
        ingredientsText: String,
        stepsText: String,
        categoriesText: String,
        note: String
    ) -> Summary {
        .init(
            source: source,
            inputIngredientCount: lines(in: ingredientsText).count,
            inputStepCount: lines(in: stepsText).count,
            inputCategoryCount: lines(in: categoriesText).count,
            hasNote: note.isNotEmpty
        )
    }

    static func logSuccess(
        logger: MHLogger,
        summary: Summary,
        draft: RecipeFormDraft
    ) {
        logger.info(
            "recipe draft build succeeded",
            metadata: summary.successMetadata(
                draft: draft
            )
        )
    }

    static func logFailure(
        logger: MHLogger,
        summary: Summary,
        error: Error
    ) {
        logger.warning(
            "recipe draft build failed",
            metadata: summary.failureMetadata(
                error: error
            )
        )
    }
}

private extension RecipeDraftLogging {
    static func formSource(
        for type: RecipeFormType
    ) -> Source {
        switch type {
        case .create,
             .duplicate:
            .formCreate
        case .edit:
            .formEdit
        }
    }

    static func lines(
        in text: String
    ) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { line in
                line.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter(\.isNotEmpty)
    }
}
