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

        try await requestDeleteConfirmation(
            dialog: .init(
                stringLiteral: RecipeDeleteCopy.confirmationDialog(for: model)
            )
        )

        _ = try await recipeActionService.delete(
            context: modelContainer.mainContext,
            recipe: model
        )

        return .result(
            dialog: .init(
                stringLiteral: RecipeDeleteCopy.successDialog(for: model)
            )
        )
    }
}
