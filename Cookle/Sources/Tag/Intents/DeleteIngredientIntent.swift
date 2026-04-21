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

        guard ingredient.recipes.orEmpty.isEmpty else {
            return .result(
                dialog: .init(
                    stringLiteral: IngredientDeleteCopy.rejectionDialog(
                        for: ingredient
                    )
                )
            )
        }

        try await requestDeleteConfirmation(
            dialog: .init(
                stringLiteral: IngredientDeleteCopy.confirmationDialog(
                    for: ingredient
                )
            )
        )

        try await tagActionService.delete(
            context: modelContainer.mainContext,
            ingredient: ingredient
        )

        return .result(
            dialog: .init(
                stringLiteral: IngredientDeleteCopy.successDialog(for: ingredient)
            )
        )
    }
}
