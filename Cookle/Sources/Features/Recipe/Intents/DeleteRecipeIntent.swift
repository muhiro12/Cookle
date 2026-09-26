import AppIntents
import SwiftData

struct DeleteRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Recipe"
    }

    @Parameter(title: "Recipe")
    private var recipe: RecipeEntity

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var recipeActionService: RecipeActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let model = try recipe.model(
            context: modelContainer.mainContext
        ) else {
            throw RecipeMutationIntentError.recipeNotFound
        }

        let deletedReview = try await confirmReviewedMutation(
            initialReview: RecipeOperations.deletionReview(
                for: model
            ),
            dialog: RecipeDeleteCopy.confirmationDialog(for:),
            missingError: RecipeMutationIntentError.recipeNotFound
        ) { review in
            try await recipeActionService.delete(
                context: modelContainer.mainContext,
                reviewed: review
            )
        }

        return .result(
            dialog: .init(
                stringLiteral: RecipeDeleteCopy.successDialog(for: deletedReview)
            )
        )
    }
}
