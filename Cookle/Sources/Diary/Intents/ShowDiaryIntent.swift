import AppIntents
import SwiftData
import SwiftUI

struct ShowDiaryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Show Diary"
    }

    @Parameter(title: "Date")
    private var date: Date

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let diary = try DiaryService.diary(
            on: date,
            context: modelContainer.mainContext
        ) else {
            return .result(dialog: "Diary not found")
        }

        let dialog = diary.date.formatted(.dateTime.year().month().day().weekday())
        return .result(dialog: .init(stringLiteral: dialog)) {
            DiaryView()
                .environment(diary)
                .safeAreaPadding()
                .modelContainer(modelContainer)
        }
    }
}
