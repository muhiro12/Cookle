import SwiftData

enum RecipeFormSaveCoordinator {
    struct Request {
        let type: RecipeFormType
        let recipe: Recipe?
        let draft: RecipeFormDraft
        let requestReview: Bool
    }

    enum Result {
        case created(Recipe)
        case updated
    }

    @MainActor
    static func save(
        context: ModelContext,
        request: Request,
        recipeActionService: RecipeActionService
    ) async throws -> Result {
        switch request.type {
        case .create,
             .duplicate:
            let outcome = try await recipeActionService.create(
                context: context,
                draft: request.draft,
                requestReview: request.requestReview
            )
            return .created(outcome.value)
        case .edit:
            guard let recipe = request.recipe else {
                throw CookleActionError.recipeNotFound
            }
            _ = try await recipeActionService.update(
                context: context,
                recipe: recipe,
                draft: request.draft,
                requestReview: request.requestReview
            )
            return .updated
        }
    }
}
