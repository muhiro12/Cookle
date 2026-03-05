import AppIntents
import SwiftData

struct CreateRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Create Recipe"
    }

    @Parameter(title: "Name")
    private var name: String
    @Parameter(title: "Serving Size")
    private var servingSize: Int
    @Parameter(title: "Cooking Time")
    private var cookingTime: Int
    @Parameter(title: "Ingredients")
    private var ingredientsText: String
    @Parameter(title: "Steps")
    private var stepsText: String
    @Parameter(title: "Categories")
    private var categoriesText: String
    @Parameter(title: "Note")
    private var note: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var recipeActionService: RecipeActionService

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<RecipeEntity> {
        let draft = try RecipeIntentDraftBuilder.makeDraft(
            input: .init(
                name: name,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredientsText: ingredientsText,
                stepsText: stepsText,
                categoriesText: categoriesText,
                note: note
            )
        )
        let recipe = try await recipeActionService.create(
            context: modelContainer.mainContext,
            draft: draft,
            requestReview: false
        )
        guard let entity = RecipeEntity(recipe) else {
            throw RecipeMutationIntentError.failedToBuildEntity
        }
        return .result(value: entity)
    }
}
