import MHPlatform
import SwiftData

@MainActor
enum CooklePlatformEnvironmentFactory {
    static func live(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> CooklePlatformEnvironment {
        let modelContainer = try ModelContainerFactory.appContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        return makeEnvironment(
            modelContainer: modelContainer,
            nativeAdUnitID: liveAdUnitID
        )
    }

    static func preview(
        modelContainer: ModelContainer
    ) -> CooklePlatformEnvironment {
        makeEnvironment(
            modelContainer: modelContainer,
            nativeAdUnitID: Secret.adUnitIDDev
        )
    }
}

private extension CooklePlatformEnvironmentFactory {
    static var liveAdUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    static func makeEnvironment(
        modelContainer: ModelContainer,
        nativeAdUnitID: String
    ) -> CooklePlatformEnvironment {
        let navigationModel = MainNavigationModel()
        let services = makeServices(
            modelContainer: modelContainer,
            navigationModel: navigationModel
        )
        let runtime = MHAppRuntime(
            configuration: makeRuntimeConfiguration(
                nativeAdUnitID: nativeAdUnitID
            )
        )
        let runtimeBootstrap = makeRuntimeBootstrap(
            runtime: runtime,
            remoteConfigurationService: services.remoteConfigurationService,
            notificationService: services.notificationService,
            routePipeline: services.routePipeline
        )

        return makeEnvironment(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            services: services,
            runtimeBootstrap: runtimeBootstrap
        )
    }

    static func makeServices(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel
    ) -> CooklePlatformServices {
        let remoteConfigurationService = RemoteConfigurationService()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: modelContainer.mainContext
        )
        let notificationService = NotificationService(
            modelContainer: modelContainer,
            routeInbox: routePipeline.inbox
        )
        let tipController = CookleTipController()

        do {
            try tipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        return .init(
            remoteConfigurationService: remoteConfigurationService,
            notificationService: notificationService,
            tipController: tipController,
            routePipeline: routePipeline
        )
    }

    static func makeEnvironment(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel,
        services: CooklePlatformServices,
        runtimeBootstrap: MHAppRuntimeBootstrap
    ) -> CooklePlatformEnvironment {
        let reviewFlow = makeReviewFlow()

        return .init(
            modelContainer: modelContainer,
            remoteConfigurationService: services.remoteConfigurationService,
            notificationService: services.notificationService,
            tipController: services.tipController,
            recipeActionService: RecipeActionService(
                notificationService: services.notificationService,
                reviewFlow: reviewFlow
            ),
            diaryActionService: DiaryActionService(),
            tagActionService: TagActionService(
                notificationService: services.notificationService
            ),
            settingsActionService: SettingsActionService(
                notificationService: services.notificationService
            ),
            navigationModel: navigationModel,
            runtimeBootstrap: runtimeBootstrap
        )
    }

    static func makeReviewFlow() -> MHReviewFlow {
        .init(
            policy: CookleReviewPolicy.request,
            logger: CookleApp.logger(
                category: "ReviewFlow",
                source: #fileID
            )
        )
    }

    static func makeRuntimeConfiguration(
        nativeAdUnitID: String
    ) -> MHAppConfiguration {
        .init(
            subscriptionProductIDs: [Secret.productID],
            subscriptionGroupID: Secret.groupID,
            nativeAdUnitID: nativeAdUnitID,
            preferencesSuiteName: CookleSharedPreferences.appGroupIdentifier,
            showsLicenses: true
        )
    }

    static func makeRuntimeBootstrap<Route: Sendable>(
        runtime: MHAppRuntime,
        remoteConfigurationService: RemoteConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeBootstrap {
        .init(
            runtime: runtime,
            lifecyclePlan: .init(
                commonTasks: [
                    .init(name: "syncSubscriptionState") {
                        syncSubscriptionStateIfNeeded(
                            runtime: runtime
                        )
                    },
                    .init(name: "loadRemoteConfiguration") {
                        try? await remoteConfigurationService.load()
                    },
                    .init(name: "synchronizeNotifications") {
                        await notificationService.synchronizeScheduledSuggestions()
                    },
                    routePipeline.task(
                        name: "synchronizePendingRoutes"
                    )
                ],
                skipFirstActivePhase: true
            ),
            routePipeline: routePipeline
        )
    }

    static func syncSubscriptionStateIfNeeded(
        runtime: MHAppRuntime
    ) {
        switch runtime.premiumStatus {
        case .unknown:
            return
        case .inactive:
            CooklePreferences.set(
                false,
                for: .isSubscribeOn
            )
            CooklePreferences.set(
                false,
                for: .isICloudOn
            )
        case .active:
            CooklePreferences.set(
                true,
                for: .isSubscribeOn
            )
        }
    }
}
