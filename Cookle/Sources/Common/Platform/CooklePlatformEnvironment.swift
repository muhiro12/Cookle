import MHAppRuntimeCore
import SwiftData
import SwiftUI

struct CooklePlatformEnvironment {
    let modelContainer: ModelContainer
    let remoteConfigurationService: RemoteConfigurationService
    let notificationService: NotificationService
    let tipController: CookleTipController
    let recipeActionService: RecipeActionService
    let diaryActionService: DiaryActionService
    let tagActionService: TagActionService
    let settingsActionService: SettingsActionService
    let navigationModel: MainNavigationModel
    let routePipeline: MHAppRoutePipeline<CookleRoute>
    let runtimeBootstrap: MHAppRuntimeBootstrap
}

extension View {
    func cooklePlatformEnvironment(
        _ environment: CooklePlatformEnvironment
    ) -> some View {
        cookleSharedEnvironment(
            environment
        )
        .mhAppRuntimeBootstrap(environment.runtimeBootstrap)
    }

    func cooklePreviewPlatformEnvironment(
        _ environment: CooklePlatformEnvironment
    ) -> some View {
        cookleSharedEnvironment(
            environment
        )
        .mhAppRuntimeEnvironment(environment.runtimeBootstrap)
    }

    private func cookleSharedEnvironment(
        _ environment: CooklePlatformEnvironment
    ) -> some View {
        self
            .modelContainer(environment.modelContainer)
            .environment(environment.remoteConfigurationService)
            .environment(environment.notificationService)
            .environment(environment.tipController)
            .environment(environment.recipeActionService)
            .environment(environment.diaryActionService)
            .environment(environment.tagActionService)
            .environment(environment.settingsActionService)
            .environment(environment.navigationModel)
            .environment(environment.routePipeline)
    }
}
