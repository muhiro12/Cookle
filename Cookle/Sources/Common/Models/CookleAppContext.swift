import MHPlatform
import SwiftData
import SwiftUI

struct CookleAppContext {
    let modelContainer: ModelContainer
    let appRuntime: MHAppRuntime
    let configurationService: ConfigurationService
    let routeInbox: MHObservableDeepLinkInbox
    let notificationService: NotificationService
    let tipController: CookleTipController
    let recipeActionService: RecipeActionService
    let diaryActionService: DiaryActionService
    let tagActionService: TagActionService
    let settingsActionService: SettingsActionService

    @MainActor
    static func live(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> Self {
        let modelContainer = try ModelContainerFactory.appContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        return make(
            modelContainer: modelContainer,
            appRuntime: makeAppRuntime(
                nativeAdUnitID: liveAdUnitID
            )
        )
    }

    @MainActor
    static func preview(
        modelContainer: ModelContainer
    ) -> Self {
        make(
            modelContainer: modelContainer,
            appRuntime: makeAppRuntime(
                nativeAdUnitID: Secret.adUnitIDDev
            )
        )
    }
}

private extension CookleAppContext {
    static var liveAdUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    @MainActor
    static func make(
        modelContainer: ModelContainer,
        appRuntime: MHAppRuntime
    ) -> Self {
        let routeInbox = MHObservableDeepLinkInbox()
        let notificationService = NotificationService(
            modelContainer: modelContainer,
            routeInbox: routeInbox
        )
        let tipController = CookleTipController()

        do {
            try tipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        let configurationService = ConfigurationService()
        let recipeActionService = RecipeActionService(
            notificationService: notificationService
        )
        let diaryActionService = DiaryActionService()
        let tagActionService = TagActionService(
            notificationService: notificationService
        )
        let settingsActionService = SettingsActionService(
            notificationService: notificationService
        )

        return .init(
            modelContainer: modelContainer,
            appRuntime: appRuntime,
            configurationService: configurationService,
            routeInbox: routeInbox,
            notificationService: notificationService,
            tipController: tipController,
            recipeActionService: recipeActionService,
            diaryActionService: diaryActionService,
            tagActionService: tagActionService,
            settingsActionService: settingsActionService
        )
    }

    @MainActor
    static func makeAppRuntime(
        nativeAdUnitID: String
    ) -> MHAppRuntime {
        .init(
            configuration: .init(
                subscriptionProductIDs: [Secret.productID],
                subscriptionGroupID: Secret.groupID,
                nativeAdUnitID: nativeAdUnitID,
                preferencesSuiteName: CookleSharedPreferences.appGroupIdentifier,
                showsLicenses: true
            )
        )
    }
}

extension View {
    func cookleAppContext(
        _ context: CookleAppContext
    ) -> some View {
        self
            .modelContainer(context.modelContainer)
            .environment(context.appRuntime)
            .environment(context.configurationService)
            .environment(context.routeInbox)
            .environment(context.notificationService)
            .environment(context.tipController)
            .environment(context.recipeActionService)
            .environment(context.diaryActionService)
            .environment(context.tagActionService)
            .environment(context.settingsActionService)
    }
}
