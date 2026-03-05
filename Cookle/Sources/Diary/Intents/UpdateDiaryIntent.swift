import AppIntents
import SwiftData

struct UpdateDiaryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Update Diary"
    }

    @Parameter(title: "Date")
    private var date: Date
    @Parameter(title: "Breakfasts")
    private var breakfasts: Set<RecipeEntity>
    @Parameter(title: "Lunches")
    private var lunches: Set<RecipeEntity>
    @Parameter(title: "Dinners")
    private var dinners: Set<RecipeEntity>
    @Parameter(title: "Note")
    private var note: String

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var diaryActionService: DiaryActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = modelContainer.mainContext
        guard let diary = try DiaryService.diary(
            on: date,
            context: context
        ) else {
            return .result(dialog: "Diary not found")
        }

        await diaryActionService.update(
            context: context,
            diary: diary,
            date: date,
            input: .init(
                breakfasts: DiaryIntentSupport.resolveRecipes(
                    from: breakfasts,
                    context: context
                ),
                lunches: DiaryIntentSupport.resolveRecipes(
                    from: lunches,
                    context: context
                ),
                dinners: DiaryIntentSupport.resolveRecipes(
                    from: dinners,
                    context: context
                ),
                note: note
            )
        )

        return .result(dialog: "Updated diary")
    }
}
