import AppIntents
import SwiftData

struct DeleteCategoryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Category"
    }

    @Parameter(title: "Category")
    private var value: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let category = try TagIntentSupport.category(
            named: value,
            context: modelContainer.mainContext
        ) else {
            throw TagMutationIntentError.categoryNotFound
        }

        let deletedReview = try await confirmReviewedMutation(
            initialReview: TagOperations.deletionReview(
                for: category
            ),
            dialog: CategoryDeleteCopy.confirmationDialog(for:),
            missingError: TagMutationIntentError.categoryNotFound
        ) { review in
            try await tagActionService.delete(
                context: modelContainer.mainContext,
                reviewed: review
            )
        }

        return .result(
            dialog: .init(
                stringLiteral: CategoryDeleteCopy.successDialog(for: deletedReview)
            )
        )
    }
}
