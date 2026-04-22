import AppIntents
import SwiftData

struct DeleteDiaryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Diary"
    }

    @Parameter(title: "Date")
    private var date: Date

    @Dependency private var modelContainer: ModelContainer
    @Dependency private var diaryActionService: DiaryActionService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let diary = try DiaryService.diary(
            on: date,
            context: modelContainer.mainContext
        ) else {
            throw DiaryMutationIntentError.diaryNotFound
        }

        try await requestDeleteConfirmation(
            dialog: .init(
                stringLiteral: DiaryDeleteCopy.confirmationDialog(for: diary)
            )
        )

        try await diaryActionService.delete(
            context: modelContainer.mainContext,
            diary: diary
        )

        return .result(
            dialog: .init(
                stringLiteral: DiaryDeleteCopy.successDialog(for: diary)
            )
        )
    }
}
