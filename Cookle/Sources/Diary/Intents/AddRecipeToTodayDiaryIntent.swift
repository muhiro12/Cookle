import AppIntents
import SwiftData

struct AddRecipeToTodayDiaryIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Recipe To Today's Diary" }

    @Parameter(title: "Recipe")
    private var recipe: RecipeEntity

    @Parameter(title: "Meal Type")
    private var type: MealType

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var diaryActionService: DiaryActionService

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = modelContainer.mainContext
        guard let model = try recipe.model(context: context) else {
            return .result(dialog: "Recipe not found")
        }
        _ = try await diaryActionService.add(
            context: context,
            date: .now,
            recipe: model,
            type: type.diaryType
        )
        return .result(dialog: "Added to today's diary")
    }
}
