import Foundation
import MHPlatform
import MHUI
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
            logging: logging,
            deliversTimers: true,
            adsConsent: CookleMonetizationConfiguration.adsConsent
        )
    }

    static func preview(
        modelContainer: ModelContainer
    ) -> CookleAppAssembly {
        // Previews skip `CookleApp.init()`, so they configure the same
        // native appearance before returning their hierarchy.
        MHTheme.standard.configureNativeAppearance()
        return makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: CookleMonetizationConfiguration.nativeAdUnitIDDev,
            logging: .preview()
        )
    }

    #if DEBUG
    /// Builds a capture assembly without an ad unit so screenshots never contain test ads.
    static func capture(
        modelContainer: ModelContainer
    ) -> CookleAppAssembly {
        makeAssembly(
            modelContainer: modelContainer,
            nativeAdUnitID: nil,
            logging: .preview(),
            isolatesCookingSession: true,
            deliversTimers: CookleCaptureConfiguration.usesTimerDelivery
        )
    }
    #endif
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
        nativeAdUnitID: String?,
        logging: CookleAppLogging,
        isolatesCookingSession: Bool = false,
        deliversTimers: Bool = false,
        adsConsent: MHAdsConsentConfiguration? = nil
    ) -> CookleAppAssembly {
        let navigationModel = MainNavigationModel()
        let cookingSessionStore = makeCookingSessionStore(isIsolated: isolatesCookingSession)
        let cookingSessionWatchSyncService = makeCookingSessionWatchSyncService(
            cookingSessionStore: cookingSessionStore,
            modelContext: modelContainer.mainContext,
            isIsolated: isolatesCookingSession
        )
        let services = makeServiceGraph(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            logging: logging
        )
        let bootstrap = makeBootstrap(
            configuration: makeRuntimeConfiguration(nativeAdUnitID: nativeAdUnitID, adsConsent: adsConsent),
            remoteConfigurationService: services.remoteConfigurationService,
            notificationService: services.notificationService,
            routePipeline: services.routePipeline
        )
        return .init(
            modelContainer: modelContainer,
            navigationModel: navigationModel,
            routeNavigator: CookleRouteNavigator(
                navigationModel: navigationModel,
                modelContext: modelContainer.mainContext,
                logger: logging.logger(
                    category: "RouteExecution",
                    source: #fileID
                )
            ),
            services: services,
            cookingSessionStore: cookingSessionStore,
            cookingSessionWatchSyncService: cookingSessionWatchSyncService,
            cookingTimerDeliveryService: .init(cookingSessionStore: cookingSessionStore, isEnabled: deliversTimers),
            recipeActionService: makeRecipeActionService(
                notificationService: services.notificationService,
                logging: logging,
                recordRecentRecipe: cookingSessionWatchSyncService.recordOpenedRecipe
            ),
            photoActionService: makePhotoActionService(
                notificationService: services.notificationService
            ),
            diaryActionService: DiaryActionService(notificationService: services.notificationService),
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
        configuration: MHAppConfiguration,
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
            configuration: configuration,
            routePipeline: routePipeline,
            lifecyclePlan: lifecyclePlan
        )
    }

    static func makeRecipeActionService(
        notificationService: NotificationService,
        logging: CookleAppLogging,
        recordRecentRecipe: @escaping @MainActor (Recipe) -> Void
    ) -> RecipeActionService {
        .init(
            notificationService: notificationService,
            recordRecentRecipe: recordRecentRecipe,
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

    static func makeCookingSessionStore(isIsolated: Bool) -> CookingSessionStore {
        #if DEBUG
        if isIsolated {
            let suiteName = CookleCaptureConfiguration.usesWatchSync
                ? "Cookle.capture.watch" : "Cookle.capture.timer"
            if CookleCaptureConfiguration.usesWatchSync || CookleCaptureConfiguration.usesTimerDelivery,
               let defaults = UserDefaults(suiteName: suiteName) {
                return .init(userDefaults: defaults)
            }
        }
        #endif
        return .init(persistsSnapshot: !isIsolated)
    }

    static func makeCookingSessionWatchSyncService(
        cookingSessionStore: CookingSessionStore,
        modelContext: ModelContext,
        isIsolated: Bool
    ) -> CookingSessionWatchSyncService {
        if isIsolated {
            #if DEBUG
            if CookleCaptureConfiguration.usesWatchSync,
               let defaults = UserDefaults(suiteName: "Cookle.capture.watch") {
                return .init(
                    cookingSessionStore: cookingSessionStore,
                    modelContext: modelContext,
                    userDefaults: defaults
                )
            }
            #endif
            return .init(cookingSessionStore: cookingSessionStore, session: nil)
        }
        return .init(
            cookingSessionStore: cookingSessionStore,
            modelContext: modelContext
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
        nativeAdUnitID: String?,
        adsConsent: MHAdsConsentConfiguration?
    ) -> MHAppConfiguration {
        .init(
            subscriptionProductIDs: [
                CookleMonetizationConfiguration.subscriptionProductID
            ],
            subscriptionGroupID: CookleMonetizationConfiguration.subscriptionGroupID,
            nativeAdUnitID: nativeAdUnitID,
            showsLicenses: true,
            adsConsent: adsConsent
        )
    }

    static func makeLifecyclePlan<Route: Sendable>(
        remoteConfigurationService: RemoteConfigurationService,
        notificationService: NotificationService,
        routePipeline: MHAppRoutePipeline<Route>
    ) -> MHAppRuntimeLifecyclePlan {
        .init(
            commonTasks: [
                .init(name: "loadRemoteConfiguration") {
                    await remoteConfigurationService.load()
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
}
