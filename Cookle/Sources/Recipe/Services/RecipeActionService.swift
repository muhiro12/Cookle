import Observation
import SwiftData

@MainActor
@Observable
final class RecipeActionService {
    private let notificationService: NotificationService
    private let reviewRequester: CookleReviewRequester

    init(
        notificationService: NotificationService,
        reviewRequester: CookleReviewRequester = .init()
    ) {
        self.notificationService = notificationService
        self.reviewRequester = reviewRequester
    }

    func create(
        context: ModelContext,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async -> Recipe {
        let recipe = RecipeFormService.create(
            context: context,
            draft: draft
        )
        await handleRecipeMutation(requestReview: requestReview)
        return recipe
    }

    func update(
        context: ModelContext,
        recipe: Recipe,
        draft: RecipeFormDraft,
        requestReview: Bool = true
    ) async {
        RecipeFormService.update(
            context: context,
            recipe: recipe,
            draft: draft
        )
        await handleRecipeMutation(requestReview: requestReview)
    }

    func delete(
        context: ModelContext,
        recipe: Recipe
    ) async throws {
        try RecipeService.delete(
            context: context,
            recipe: recipe
        )
        await handleRecipeMutation(requestReview: false)
    }

    func replaceGeneratedPhoto(
        context: ModelContext,
        recipe: Recipe,
        data: Data
    ) async throws {
        let updatedDraft = RecipeFormDraft(
            name: recipe.name,
            photos: [
                .init(
                    data: data.compressed(),
                    source: .imagePlayground
                )
            ],
            servingSize: recipe.servingSize,
            cookingTime: recipe.cookingTime,
            ingredients: recipe.ingredientObjects.orEmpty.sorted().compactMap { object in
                guard let ingredient = object.ingredient else {
                    return nil
                }
                return .init(
                    ingredient: ingredient.value,
                    amount: object.amount
                )
            },
            steps: recipe.steps,
            categories: recipe.categories.orEmpty.map(\.value),
            note: recipe.note
        )

        try await update(
            context: context,
            recipe: recipe,
            draft: updatedDraft,
            requestReview: false
        )
    }
}

private extension RecipeActionService {
    func handleRecipeMutation(requestReview: Bool) async {
        CookleWidgetReloader.reloadRecipeWidgets()
        await notificationService.synchronizeScheduledSuggestions()

        if requestReview {
            await reviewRequester.requestIfNeeded()
        }
    }
}
