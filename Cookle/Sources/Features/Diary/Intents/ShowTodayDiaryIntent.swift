import AppIntents
import SwiftData
import SwiftUI

struct ShowTodayDiaryIntent: AppIntent {
    static var title: LocalizedStringResource { "Show Today's Diary" }

    // This returns the whole diary — meals and the person's own notes — as a
    // snippet. The default policy would render that on a locked device.
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresAuthentication
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
            dialog: .init(
                stringLiteral: String(localized: "No diary for today")
            )
        )
    }
}
