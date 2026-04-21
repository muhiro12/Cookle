import MHPlatform
import SwiftData
import SwiftUI

@MainActor
final class CookleAppAssembly {
    let modelContainer: ModelContainer
    let navigationModel: MainNavigationModel
    let services: CookleAppServices
    let cookingSessionStore: CookingSessionStore
    let cookingSessionWatchSyncService: CookingSessionWatchSyncService
    let recipeActionService: RecipeActionService
    let photoActionService: PhotoActionService
    let diaryActionService: DiaryActionService
    let tagActionService: TagActionService
    let settingsActionService: SettingsActionService
    let bootstrap: MHAppRuntimeBootstrap

    init(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel,
        services: CookleAppServices,
        cookingSessionStore: CookingSessionStore,
        cookingSessionWatchSyncService: CookingSessionWatchSyncService,
        recipeActionService: RecipeActionService,
        photoActionService: PhotoActionService,
        diaryActionService: DiaryActionService,
        tagActionService: TagActionService,
        settingsActionService: SettingsActionService,
        bootstrap: MHAppRuntimeBootstrap
    ) {
        self.modelContainer = modelContainer
        self.navigationModel = navigationModel
        self.services = services
        self.cookingSessionStore = cookingSessionStore
        self.cookingSessionWatchSyncService = cookingSessionWatchSyncService
        self.recipeActionService = recipeActionService
        self.photoActionService = photoActionService
        self.diaryActionService = diaryActionService
        self.tagActionService = tagActionService
        self.settingsActionService = settingsActionService
        self.bootstrap = bootstrap
    }
}

extension View {
    func cookleAppAssembly(
        _ assembly: CookleAppAssembly
    ) -> some View {
        cookleSharedEnvironment(
            assembly
        )
        .mhAppRuntimeBootstrap(assembly.bootstrap)
    }

    func cooklePreviewAppAssembly(
        _ assembly: CookleAppAssembly
    ) -> some View {
        cookleSharedEnvironment(
            assembly
        )
        .mhAppRuntimeEnvironment(assembly.bootstrap)
    }

    private func cookleSharedEnvironment(
        _ assembly: CookleAppAssembly
    ) -> some View {
        self
            .modelContainer(assembly.modelContainer)
            .environment(assembly.services.logging)
            .environment(assembly.services.remoteConfigurationService)
            .environment(assembly.services.notificationService)
            .environment(assembly.services.tipController)
            .environment(assembly.recipeActionService)
            .environment(assembly.photoActionService)
            .environment(assembly.diaryActionService)
            .environment(assembly.tagActionService)
            .environment(assembly.settingsActionService)
            .environment(assembly.cookingSessionStore)
            .environment(assembly.navigationModel)
            .environment(assembly.services.routePipeline)
    }
}
