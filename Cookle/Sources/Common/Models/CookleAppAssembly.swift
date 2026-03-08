import MHPlatform
import SwiftData

@MainActor
struct CookleAppAssembly {
    let dependencies: CookleAppDependencies
    let bootstrap: MHAppRuntimeBootstrap

    static func live(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> Self {
        let modelContainer = try ModelContainerFactory.appContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        return make(
            modelContainer: modelContainer,
            nativeAdUnitID: liveAdUnitID
        )
    }

    static func preview(
        modelContainer: ModelContainer
    ) -> Self {
        make(
            modelContainer: modelContainer,
            nativeAdUnitID: Secret.adUnitIDDev
        )
    }
}

private extension CookleAppAssembly {
    static var liveAdUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    static func make(
        modelContainer: ModelContainer,
        nativeAdUnitID: String
    ) -> Self {
        let navigationModel = MainNavigationModel()
        let services = makeServices(
            modelContainer: modelContainer,
            navigationModel: navigationModel
        )
        let dependencies = makeDependencies(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            services: services
        )
        let runtime = MHAppRuntime(
            configuration: makeRuntimeConfiguration(
                nativeAdUnitID: nativeAdUnitID
            )
        )
        let lifecyclePlan = makeLifecyclePlan(
            runtime: runtime,
            configurationService: services.configurationService,
            notificationService: services.notificationService,
            routePipeline: services.routePipeline
        )

        return .init(
            dependencies: dependencies,
            bootstrap: .init(
                runtime: runtime,
                lifecyclePlan: lifecyclePlan,
                routePipeline: services.routePipeline
            )
        )
    }

    static func makeServices(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel
    ) -> CookleAppServices {
        let configurationService = ConfigurationService()
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
            configurationService: configurationService,
            notificationService: notificationService,
            tipController: tipController,
            routePipeline: routePipeline
        )
    }

    static func makeDependencies(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel,
        services: CookleAppServices
    ) -> CookleAppDependencies {
        let reviewFlow = makeReviewFlow()

        return .init(
            modelContainer: modelContainer,
            configurationService: services.configurationService,
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
            navigationModel: navigationModel
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

    static func makeLifecyclePlan<Route: Sendable>(
        runtime: MHAppRuntime,
        configurationService: ConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeLifecyclePlan {
        .init(
            commonTasks: [
                .init(name: "syncSubscriptionState") {
                    syncSubscriptionStateIfNeeded(
                        runtime: runtime
                    )
                },
                .init(name: "loadConfiguration") {
                    try? await configurationService.load()
                },
                .init(name: "synchronizeNotifications") {
                    await notificationService.synchronizeScheduledSuggestions()
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
