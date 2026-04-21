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

        try await requestDeleteConfirmation(
            dialog: .init(
                stringLiteral: CategoryDeleteCopy.confirmationDialog(for: category)
            )
        )

        try await tagActionService.delete(
            context: modelContainer.mainContext,
            category: category
        )

        return .result(
            dialog: .init(
                stringLiteral: CategoryDeleteCopy.successDialog(for: category)
            )
        )
    }
}
