import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class SettingsActionService {
    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func deleteAllData(context: ModelContext) async throws {
        _ = try await MHDestructiveResetService.runThrowing(
            steps: [
                .init(name: "deleteAllData") {
                    try await MainActor.run {
                        try DataResetService.deleteAll(context: context)
                    }
                },
                .init(name: "reloadTodayDiaryWidget") {
                    await MainActor.run {
                        CookleWidgetReloader.reloadTodayDiaryWidget()
                    }
                },
                .init(name: "reloadRecipeWidgets") {
                    await MainActor.run {
                        CookleWidgetReloader.reloadRecipeWidgets()
                    }
                },
                .init(name: "synchronizeScheduledSuggestions") { [self] in
                    await notificationService.synchronizeScheduledSuggestions()
                }
            ]
        )
    }
}
