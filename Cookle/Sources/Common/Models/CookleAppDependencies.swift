import SwiftData
import SwiftUI

struct CookleAppDependencies {
    let modelContainer: ModelContainer
    let configurationService: ConfigurationService
    let notificationService: NotificationService
    let tipController: CookleTipController
    let recipeActionService: RecipeActionService
    let diaryActionService: DiaryActionService
    let tagActionService: TagActionService
    let settingsActionService: SettingsActionService
    let navigationModel: MainNavigationModel
}

extension View {
    func cookleAppDependencies(
        _ dependencies: CookleAppDependencies
    ) -> some View {
        self
            .modelContainer(dependencies.modelContainer)
            .environment(dependencies.configurationService)
            .environment(dependencies.notificationService)
            .environment(dependencies.tipController)
            .environment(dependencies.recipeActionService)
            .environment(dependencies.diaryActionService)
            .environment(dependencies.tagActionService)
            .environment(dependencies.settingsActionService)
            .environment(dependencies.navigationModel)
    }
}
