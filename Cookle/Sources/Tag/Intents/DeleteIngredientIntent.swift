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
        try await requestDeleteConfirmation(
            dialog: .init(stringLiteral: "Delete ingredient \(value)?")
        )

        guard let ingredient = try TagIntentSupport.ingredient(
            named: value,
            context: modelContainer.mainContext
        ) else {
            throw TagMutationIntentError.ingredientNotFound
        }

        try await tagActionService.delete(
            context: modelContainer.mainContext,
            ingredient: ingredient
        )
        return .result(dialog: "Deleted ingredient")
    }
}
