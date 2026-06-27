import SwiftData

enum RecipeFormSaveCoordinator {
    enum Result {
        case created(Recipe)
        case updated
    }

    @MainActor
    static func save(
        context: ModelContext,
        type: RecipeFormType,
        recipe: Recipe?,
        draft: RecipeFormDraft,
        recipeActionService: RecipeActionService
    ) async throws -> Result {
        let requestReview = !draft.photos.isEmpty
            || CookleImagePlayground.isSupported == false

        switch type {
        case .create,
             .duplicate:
            let outcome = try await recipeActionService.create(
                context: context,
                draft: draft,
                requestReview: requestReview
            )
            return .created(outcome.value)
        case .edit:
            guard let recipe else {
                throw CookleActionError.recipeNotFound
            }
            try await recipeActionService.update(
                context: context,
                recipe: recipe,
                draft: draft,
                requestReview: requestReview
            )
            return .updated
        }
    }
}
