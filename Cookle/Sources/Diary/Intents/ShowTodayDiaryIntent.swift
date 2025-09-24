import AppIntents
import SwiftData
import SwiftUI

struct ShowTodayDiaryIntent: AppIntent {
    static var title: LocalizedStringResource { "Show Today's Diary" }

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        if let diary = try DiaryService.diary(on: .now, context: modelContainer.mainContext) {
            return .result(dialog: .init(stringLiteral: diary.date.formatted(.dateTime.year().month().day().weekday()))) {
                DiaryView()
                    .environment(diary)
                    .safeAreaPadding()
                    .modelContainer(modelContainer)
            }
        }
        return .result(dialog: "No diary for today")
    }
}
