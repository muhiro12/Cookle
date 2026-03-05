import Foundation

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
        input: Input
    ) throws -> RecipeFormDraft {
        try RecipeFormService.makeDraft(
            name: input.name,
            servingSize: input.servingSize,
            cookingTime: input.cookingTime,
            ingredientsText: input.ingredientsText,
            stepsText: input.stepsText,
            categoriesText: input.categoriesText,
            note: input.note
        )
    }
}
