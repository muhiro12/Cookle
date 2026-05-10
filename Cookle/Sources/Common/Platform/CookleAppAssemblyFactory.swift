import MHPlatform
import SwiftData

@MainActor
enum CookleAppAssemblyFactory {
    nonisolated static func prepareLiveModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        logger: MHLogger
    ) throws -> ModelContainer {
        try ModelContainerFactory.appContainer(
            cloudKitDatabase: cloudKitDatabase,
            logger: logger
        )
    }

    static func makeLiveAssembly(
        modelContainer: ModelContainer,
        logging: CookleAppLogging
    ) -> CookleAppAssembly {
        makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: liveAdUnitID,
            logging: logging
        )
    }

    static func preview(
        modelContainer: ModelContainer
    ) -> CookleAppAssembly {
        makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: CookleMonetizationConfiguration.nativeAdUnitIDDev,
            logging: .preview()
        )
    }
}

private extension CookleAppAssemblyFactory {
    static var liveAdUnitID: String {
        #if DEBUG
        CookleMonetizationConfiguration.nativeAdUnitIDDev
        #else
        CookleMonetizationConfiguration.nativeAdUnitID
        #endif
    }

    static func makeAssembly(
        modelContainer: ModelContainer,
        nativeAdUnitID: String,
        logging: CookleAppLogging
    ) -> CookleAppAssembly {
        let navigationModel = MainNavigationModel()
        let cookingSessionStore = CookingSessionStore()
        let cookingSessionWatchSyncService = makeCookingSessionWatchSyncService(
            cookingSessionStore: cookingSessionStore
        )
        let services = makeServiceGraph(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            logging: logging
        )
        let bootstrap = makeBootstrap(
            nativeAdUnitID: nativeAdUnitID,
            remoteConfigurationService: services.remoteConfigurationService,
            notificationService: services.notificationService,
            routePipeline: services.routePipeline
        )
        return .init(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            services: services,
            cookingSessionStore: cookingSessionStore,
            cookingSessionWatchSyncService: cookingSessionWatchSyncService,
            recipeActionService: makeRecipeActionService(
                notificationService: services.notificationService,
                logging: logging
            ),
            photoActionService: makePhotoActionService(
                notificationService: services.notificationService
            ),
            diaryActionService: DiaryActionService(),
            tagActionService: TagActionService(
                notificationService: services.notificationService
            ),
            settingsActionService: SettingsActionService(
                notificationService: services.notificationService
            ),
            bootstrap: bootstrap
        )
    }

    static func makeBootstrap<Route: Sendable>(
        nativeAdUnitID: String,
        remoteConfigurationService: RemoteConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeBootstrap {
        let lifecyclePlan = makeLifecyclePlan(
            remoteConfigurationService: remoteConfigurationService,
            notificationService: notificationService,
            routePipeline: routePipeline
        )
        return .init(
            configuration: makeRuntimeConfiguration(
                nativeAdUnitID: nativeAdUnitID
            ),
            lifecyclePlan: lifecyclePlan,
            routePipeline: routePipeline
        )
    }

    static func makeRecipeActionService(
        notificationService: NotificationService,
        logging: CookleAppLogging
    ) -> RecipeActionService {
        .init(
            notificationService: notificationService,
            reviewFlow: makeReviewFlow(
                logging: logging
            ),
            saveLogger: logging.logger(
                category: "RecipeSave",
                source: #fileID
            )
        )
    }

    static func makePhotoActionService(
        notificationService: NotificationService
    ) -> PhotoActionService {
        .init(
            notificationService: notificationService
        )
    }

    static func makeCookingSessionWatchSyncService(
        cookingSessionStore: CookingSessionStore
    ) -> CookingSessionWatchSyncService {
        .init(
            cookingSessionStore: cookingSessionStore
        )
    }

    static func makeServiceGraph(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel,
        logging: CookleAppLogging
    ) -> CookleAppServices {
        let remoteConfigurationService = RemoteConfigurationService()
        let routePipeline = MainRouteService.makeRoutePipeline(
            navigationModel: navigationModel,
            modelContext: modelContainer.mainContext,
            logger: logging.logger(
                category: "RouteExecution",
                source: #fileID
            )
        )
        let notificationService = NotificationService(
            modelContainer: modelContainer,
            routeInbox: routePipeline.inbox,
            syncLogger: logging.logger(
                category: "NotificationSync",
                source: #fileID
            ),
            routeLogger: logging.logger(
                category: "NotificationRoute",
                source: #fileID
            )
        )
        let tipController = CookleTipController()

        do {
            try tipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        return .init(
            logging: logging,
            remoteConfigurationService: remoteConfigurationService,
            notificationService: notificationService,
            tipController: tipController,
            routePipeline: routePipeline
        )
    }

    static func makeReviewFlow(
        logging: CookleAppLogging
    ) -> MHReviewFlow {
        .init(
            policy: CookleReviewPolicy.request,
            logger: logging.logger(
                category: "ReviewFlow",
                source: #fileID
            )
        )
    }

    static func makeRuntimeConfiguration(
        nativeAdUnitID: String
    ) -> MHAppConfiguration {
        .init(
            subscriptionProductIDs: [
                CookleMonetizationConfiguration.subscriptionProductID
            ],
            subscriptionGroupID: CookleMonetizationConfiguration.subscriptionGroupID,
            nativeAdUnitID: nativeAdUnitID,
            showsLicenses: true
        )
    }

    static func makeLifecyclePlan<Route: Sendable>(
        remoteConfigurationService: RemoteConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeLifecyclePlan {
        .init(
            commonTasks: [
                .runtime(name: "syncSubscriptionState") { runtime in
                    syncSubscriptionStateIfNeeded(runtime: runtime)
                },
                .init(name: "loadRemoteConfiguration") {
                    try? await remoteConfigurationService.load()
                },
                .init(name: "synchronizeNotifications") {
                    notificationService.scheduleLifecycleSynchronization()
                },
                routePipeline.task(
                    name: "synchronizePendingRoutes"
                )
            ],
            skipFirstActivePhase: true
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
                for: \.isSubscribeOn
            )
            CooklePreferences.set(
                false,
                for: \.isICloudOn
            )
        case .active:
            CooklePreferences.set(
                true,
                for: \.isSubscribeOn
            )
        }
    }
}
