import AppIntents
import SwiftData
import SwiftUI

struct ShowTodayDiaryIntent: AppIntent {
    static var title: LocalizedStringResource { "Show Today's Diary" }

    // Diary reads use the same policy as recipe reads. System Siri and
    // Shortcuts settings still control invocation while the device is locked.
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .alwaysAllowed
    }

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        if let diary = try DiaryOperations.diary(on: .now, context: modelContainer.mainContext) {
            let dialog = diary.date.formatted(
                .dateTime.year().month().day().weekday()
            )
            return .result(dialog: .init(stringLiteral: dialog)) {
                DiaryView()
                    .environment(diary)
                    .safeAreaPadding()
                    .modelContainer(modelContainer)
            }
        }
        return .result(
            dialog: .init("No diary for today")
        )
    }
}
