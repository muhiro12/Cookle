import Foundation
import MHPlatform

enum RecipeIntentDraftBuilder {
    struct Input {
        let name: String
        let servingSize: Int
        let cookingTime: Int
        let ingredientsText: String
        let stepsText: String
        let categoriesText: String
        let note: String
    }

    static func makeDraft(
        input: Input,
        source: RecipeDraftLogging.Source,
        logger: MHLogger
    ) throws -> RecipeFormDraft {
        let summary = RecipeDraftLogging.intentSummary(
            source: source,
            ingredientsText: input.ingredientsText,
            stepsText: input.stepsText,
            categoriesText: input.categoriesText,
            note: input.note
        )

        do {
            let draft = try RecipeFormOperations.makeDraft(
                input: .init(
                    name: input.name,
                    servingSize: input.servingSize,
                    cookingTime: input.cookingTime,
                    ingredientsText: input.ingredientsText,
                    stepsText: input.stepsText,
                    categoriesText: input.categoriesText,
                    note: input.note
                )
            )
            RecipeDraftLogging.logSuccess(
                logger: logger,
                summary: summary,
                draft: draft
            )
            return draft
        } catch {
            RecipeDraftLogging.logFailure(
                logger: logger,
                summary: summary,
                error: error
            )
            throw error
        }
    }
}
