import AppIntents
import SwiftData

struct RenameCategoryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Rename Category"
    }

    @Parameter(title: "Current Category")
    private var currentValue: String
    @Parameter(title: "New Name")
    private var newValue: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let category = try TagIntentSupport.category(
            named: currentValue,
            context: modelContainer.mainContext
        ) else {
            throw TagMutationIntentError.categoryNotFound
        }

        try await tagActionService.rename(
            context: modelContainer.mainContext,
            category: category,
            value: newValue
        )
        return .result(dialog: "Renamed category")
    }
}
