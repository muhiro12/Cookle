import MHPlatform
import SwiftData

@MainActor
enum CookleAppAssemblyFactory {
    nonisolated static func prepareLiveModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        try ModelContainerFactory.appContainer(
            cloudKitDatabase: cloudKitDatabase
        )
    }

    static func makeLiveAssembly(
        modelContainer: ModelContainer
    ) -> CookleAppAssembly {
        makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: liveAdUnitID
        )
    }

    static func preview(
        modelContainer: ModelContainer
    ) -> CookleAppAssembly {
        makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: Secret.adUnitIDDev
        )
    }
}

private extension CookleAppAssemblyFactory {
    static var liveAdUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    static func makeAssembly(
        modelContainer: ModelContainer,
        nativeAdUnitID: String
    ) -> CookleAppAssembly {
        let navigationModel = MainNavigationModel()
        let services = makeServiceGraph(
            modelContainer: modelContainer,
            navigationModel: navigationModel
        )
        let runtimeConfiguration = makeRuntimeConfiguration(
            nativeAdUnitID: nativeAdUnitID
        )
        let bootstrap = makeBootstrap(
            configuration: runtimeConfiguration,
            routePipeline: services.routePipeline
        ) { runtimeProvider in
            makeLifecyclePlan(
                runtimeProvider: runtimeProvider,
                remoteConfigurationService: services.remoteConfigurationService,
                notificationService: services.notificationService,
                routePipeline: services.routePipeline
            )
        }
        let reviewFlow = makeReviewFlow()

        return .init(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            services: services,
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
            bootstrap: bootstrap
        )
    }

    static func makeServiceGraph(
        modelContainer: ModelContainer,
        navigationModel: MainNavigationModel
    ) -> CookleAppServices {
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

    static func makeBootstrap<Route: Sendable>(
        configuration: MHAppConfiguration,
        routePipeline: MHAppRoutePipeline<Route>,
        lifecyclePlan: (
            @escaping @MainActor () -> MHAppRuntime?
        ) -> MHAppRuntimeLifecyclePlan
    ) -> MHAppRuntimeBootstrap {
        let runtime = MHAppRuntime(
            configuration: configuration
        )
        return MHAppRuntimeBootstrap(
            runtime: runtime,
            lifecyclePlan: lifecyclePlan {
                runtime
            },
            routePipeline: routePipeline
        )
    }

    static func makeLifecyclePlan<Route: Sendable>(
        runtimeProvider: @escaping @MainActor () -> MHAppRuntime?,
        remoteConfigurationService: RemoteConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeLifecyclePlan {
        .init(
            commonTasks: [
                .init(name: "syncSubscriptionState") {
                    guard let runtime = runtimeProvider() else {
                        assertionFailure(
                            "MHAppRuntimeBootstrap runtime was unavailable during subscription sync."
                        )
                        return
                    }

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
