import AppIntents
import SwiftData

struct DeleteIngredientIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Ingredient"
    }

    @Parameter(title: "Ingredient")
    private var value: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let ingredient = try TagIntentSupport.ingredient(
            named: value,
            context: modelContainer.mainContext
        ) else {
            throw TagMutationIntentError.ingredientNotFound
        }

        let review = TagOperations.deletionReview(
            for: ingredient
        )
        guard review.recipeCount == .zero else {
            return .result(
                dialog: .init(
                    stringLiteral: IngredientDeleteCopy.rejectionDialog(
                        for: review
                    )
                )
            )
        }

        let deletedReview = try await confirmReviewedMutation(
            initialReview: review,
            dialog: IngredientDeleteCopy.confirmationDialog(for:),
            missingError: TagMutationIntentError.ingredientNotFound
        ) { reviewedDeletion in
            let result = try await tagActionService.delete(
                context: modelContainer.mainContext,
                reviewed: reviewedDeletion
            )
            // A recipe started using the ingredient; deletion stays unavailable.
            if case .changed(let currentReview) = result,
               currentReview.recipeCount > .zero {
                throw TagMutationIntentError.ingredientInUse(currentReview.value)
            }
            return result
        }

        return .result(
            dialog: .init(
                stringLiteral: IngredientDeleteCopy.successDialog(for: deletedReview)
            )
        )
    }
}
