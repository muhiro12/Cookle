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
        let formattedDate = date.formatted(.dateTime.year().month().day())
        try await requestDeleteConfirmation(
            dialog: .init(stringLiteral: "Delete diary for \(formattedDate)?")
        )

        guard let diary = try DiaryService.diary(
            on: date,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Diary not found")
        }

        try await diaryActionService.delete(
            context: modelContainer.mainContext,
            diary: diary
        )

        return .result(dialog: .init(stringLiteral: "Deleted diary for \(formattedDate)"))
    }
}
