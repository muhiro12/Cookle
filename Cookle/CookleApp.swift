//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import AppIntents
import GoogleMobileAdsWrapper
import LicenseListWrapper
import StoreKitWrapper
import SwiftData
import SwiftUI
import TipKit

@main
struct CookleApp: App {
    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(.isICloudOn)
    private var isICloudOn
    @AppStorage(.isDebugOn)
    private var isDebugOn
    @AppStorage(.lastLaunchedAppVersion)
    private var lastLaunchedAppVersion

    private let sharedGoogleMobileAdsController: GoogleMobileAdsController
    private let sharedModelContainer: ModelContainer
    private let sharedStore: Store
    private let sharedConfigurationService: ConfigurationService
    private let sharedRouteInbox: MainRouteInbox
    private let sharedNotificationService: NotificationService
    private let sharedTipController: CookleTipController
    private let sharedRecipeActionService: RecipeActionService
    private let sharedDiaryActionService: DiaryActionService
    private let sharedTagActionService: TagActionService
    private let sharedSettingsActionService: SettingsActionService

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .modelContainer(sharedModelContainer)
                .environment(sharedGoogleMobileAdsController)
                .environment(sharedStore)
                .environment(sharedConfigurationService)
                .environment(sharedRouteInbox)
                .environment(sharedNotificationService)
                .environment(sharedTipController)
                .environment(sharedRecipeActionService)
                .environment(sharedDiaryActionService)
                .environment(sharedTagActionService)
                .environment(sharedSettingsActionService)
                .task {
                    await performStartupTasks()
                }
        }
    }

    @MainActor
    init() {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        sharedModelContainer = Self.makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )

        sharedGoogleMobileAdsController = .init(
            adUnitID: Self.adUnitID
        )

        sharedStore = .init()
        sharedConfigurationService = .init()
        sharedRouteInbox = .init()
        sharedNotificationService = .init(
            modelContainer: sharedModelContainer,
            routeInbox: sharedRouteInbox
        )
        sharedTipController = .init()
        sharedRecipeActionService = .init(
            notificationService: sharedNotificationService
        )
        sharedDiaryActionService = .init()
        sharedTagActionService = .init()
        sharedSettingsActionService = .init(
            notificationService: sharedNotificationService
        )

        CookleShortcuts.updateAppShortcutParameters()

        registerAppIntentDependencies()
        configureTipController()
        updateLastLaunchedVersion()
    }
}

private extension CookleApp {
    static var adUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    static func makeModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) -> ModelContainer {
        do {
            return try ModelContainerFactory.appContainer(
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }
    }

    func performStartupTasks() async {
        #if DEBUG
        isDebugOn = true
        #endif

        sharedGoogleMobileAdsController.start()
        sharedStore.open(
            groupID: Secret.groupID,
            productIDs: [Secret.productID]
        ) { products in
            isSubscribeOn = products.contains { product in
                product.id == Secret.productID
            }
            if !isSubscribeOn {
                isICloudOn = false
            }
        }

        await sharedNotificationService.synchronizeScheduledSuggestions()
    }

    func registerAppIntentDependencies() {
        // Provide dependencies for AppIntents entity queries.
        let modelContainerForDependency = sharedModelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let recipeActionServiceForDependency = sharedRecipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = sharedDiaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = sharedTagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = sharedSettingsActionService
        AppDependencyManager.shared.add { settingsActionServiceForDependency }
    }

    func configureTipController() {
        do {
            try sharedTipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func updateLastLaunchedVersion() {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }
}
