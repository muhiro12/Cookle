import AppIntents
import SwiftData

struct RenameIngredientIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Rename Ingredient"
    }

    @Parameter(title: "Current Ingredient")
    private var currentValue: String
    @Parameter(title: "New Name")
    private var newValue: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var tagActionService: TagActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let ingredient = try TagIntentSupport.ingredient(
            named: currentValue,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Ingredient not found")
        }

        do {
            try await tagActionService.rename(
                context: modelContainer.mainContext,
                ingredient: ingredient,
                value: newValue
            )
            return .result(dialog: "Renamed ingredient")
        } catch {
            return .result(dialog: .init(stringLiteral: error.localizedDescription))
        }
    }
}
