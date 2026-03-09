import GoogleMobileAdsWrapper
import LicenseListWrapper
import MHAppRuntimeCore
import MHPreferences
import MHReviewPolicy
import StoreKitWrapper
import SwiftData
import SwiftUI

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
        let runtimeConfiguration = makeRuntimeConfiguration(
            nativeAdUnitID: nativeAdUnitID
        )
        let runtime = makeRuntime(
            configuration: runtimeConfiguration
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
            routePipeline: services.routePipeline,
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

    static func makeRuntime(
        configuration: MHAppConfiguration
    ) -> MHAppRuntime {
        let normalizedSubscriptionProductIDs = normalizeTextSet(
            configuration.subscriptionProductIDs
        )
        let normalizedSubscriptionGroupID = normalizeText(
            configuration.subscriptionGroupID
        )
        let normalizedNativeAdUnitID = normalizeText(
            configuration.nativeAdUnitID
        )
        let preferenceStore = makePreferenceStore(
            suiteName: configuration.preferencesSuiteName
        )
        let storeBridge = makeStoreBridge(
            groupID: normalizedSubscriptionGroupID,
            productIDs: normalizedSubscriptionProductIDs
        )
        let adsBridge = makeAdsBridge(
            nativeAdUnitID: normalizedNativeAdUnitID
        )
        let licensesViewBuilder = makeLicensesViewBuilder(
            showsLicenses: configuration.showsLicenses
        )

        return .init(
            configuration: configuration,
            preferenceStore: preferenceStore,
            startStore: storeBridge.start,
            subscriptionSectionViewBuilder: storeBridge.subscriptionSection,
            startAds: adsBridge.start,
            nativeAdViewBuilder: adsBridge.nativeAdView,
            licensesViewBuilder: licensesViewBuilder
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

    static func normalizeText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }

        let normalized = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalized.isEmpty == false else {
            return nil
        }

        return normalized
    }

    static func normalizeTextSet(_ values: [String]) -> [String] {
        var normalizedValues: [String] = []
        var uniqueValues = Set<String>()

        for value in values {
            guard let normalizedValue = normalizeText(value) else {
                continue
            }
            guard uniqueValues.contains(normalizedValue) == false else {
                continue
            }

            uniqueValues.insert(normalizedValue)
            normalizedValues.append(normalizedValue)
        }

        return normalizedValues
    }

    static func makeLicensesViewBuilder(
        showsLicenses: Bool
    ) -> MHAppRuntime.LicensesViewBuilder {
        {
            if showsLicenses {
                AnyView(LicenseListView())
            } else {
                AnyView(EmptyView())
            }
        }
    }

    static func makeStoreBridge(
        groupID: String?,
        productIDs: [String]
    ) -> (
        start: MHAppRuntime.StartStore,
        subscriptionSection: MHAppRuntime.SubscriptionSectionViewBuilder
    ) {
        let store = Store()

        let start: MHAppRuntime.StartStore = { purchasedProductIDsDidSet in
            store.open(
                groupID: groupID,
                productIDs: productIDs
            ) { products in
                let purchasedProductIDs = Set(products.map(\.id))
                purchasedProductIDsDidSet(purchasedProductIDs)
            }
        }

        let subscriptionSection: MHAppRuntime.SubscriptionSectionViewBuilder = {
            AnyView(store.buildSubscriptionSection())
        }

        return (
            start: start,
            subscriptionSection: subscriptionSection
        )
    }

    static func makeAdsBridge(
        nativeAdUnitID: String?
    ) -> (
        start: MHAppRuntime.StartAds?,
        nativeAdView: MHAppRuntime.NativeAdViewBuilder?
    ) {
        guard let nativeAdUnitID else {
            return (
                start: nil,
                nativeAdView: nil
            )
        }

        let controller = GoogleMobileAdsController(
            adUnitID: nativeAdUnitID
        )
        let start: MHAppRuntime.StartAds = {
            controller.start()
        }
        let nativeAdView: MHAppRuntime.NativeAdViewBuilder = { size in
            AnyView(
                controller.buildNativeAd(
                    nativeAdSizeID(for: size)
                )
            )
        }

        return (
            start: start,
            nativeAdView: nativeAdView
        )
    }

    static func makePreferenceStore(
        suiteName: String?
    ) -> MHPreferenceStore {
        guard let normalizedSuiteName = normalizeText(suiteName),
              let userDefaults = UserDefaults(
                suiteName: normalizedSuiteName
              ) else {
            return .init()
        }

        return .init(userDefaults: userDefaults)
    }

    static func nativeAdSizeID(
        for size: MHNativeAdSize
    ) -> String {
        switch size {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        }
    }
}
