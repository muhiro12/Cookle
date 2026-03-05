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
        try await requestDeleteConfirmation(
            dialog: .init(stringLiteral: "Delete \(recipe.name)?")
        )

        guard let model = try recipe.model(
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Recipe not found")
        }

        try await recipeActionService.delete(
            context: modelContainer.mainContext,
            recipe: model
        )

        return .result(dialog: .init(stringLiteral: "Deleted \(recipe.name)"))
    }
}
