import MHPlatform

enum RecipeIntentDraftBuilder {
    static func makeDraft(
        input: RecipeFormInput,
        source: RecipeDraftLogging.Source,
        logger: MHLogger
    ) throws -> RecipeFormDraft {
        let summary = RecipeDraftLogging.intentSummary(
            source: source,
            input: input
        )

        do {
            let draft = try RecipeFormOperations.makeDraft(
                input: input
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
