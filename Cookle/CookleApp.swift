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
    private let sharedNotificationService: NotificationService
    private let sharedTipController: CookleTipController
    private let sharedRecipeSummaryPreviewStore: RecipeSummaryPreviewStore

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .modelContainer(sharedModelContainer)
                .environment(sharedGoogleMobileAdsController)
                .environment(sharedStore)
                .environment(sharedConfigurationService)
                .environment(sharedNotificationService)
                .environment(sharedTipController)
                .environment(sharedRecipeSummaryPreviewStore)
                .task {
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
        }
    }

    @MainActor
    init() {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        do {
            let modelContainer = try ModelContainerFactory.appContainer(
                cloudKitDatabase: cloudKitDatabase
            )
            sharedModelContainer = modelContainer
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }

        sharedGoogleMobileAdsController = .init(
            adUnitID: {
                #if DEBUG
                Secret.adUnitIDDev
                #else
                Secret.adUnitID
                #endif
            }()
        )

        sharedStore = .init()
        sharedConfigurationService = .init()
        sharedNotificationService = .init(modelContainer: sharedModelContainer)
        sharedTipController = .init()
        sharedRecipeSummaryPreviewStore = .init()

        CookleShortcuts.updateAppShortcutParameters()

        // Provide dependencies for AppIntents entity queries
        let modelContainerForDependency = sharedModelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }

        do {
            try sharedTipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }
}
