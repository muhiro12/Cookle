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

@main
struct CookleApp: App {
    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    private let sharedGoogleMobileAdsController: GoogleMobileAdsController
    private let sharedModelContainer: ModelContainer
    private let sharedStore: Store
    private let sharedConfigurationService: ConfigurationService

    init() {
        sharedGoogleMobileAdsController = .init(
            adUnitID: {
                #if DEBUG
                Secret.adUnitIDDev
                #else
                Secret.adUnitID
                #endif
            }()
        )

        // Centralize ModelContainer at the App level (like Incomes)
        sharedModelContainer = try! .init(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                cloudKitDatabase: CooklePreferences.bool(for: .isICloudOn) ? .automatic : .none
            )
        )

        sharedStore = .init()
        sharedConfigurationService = .init()

        CookleShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .modelContainer(sharedModelContainer)
                .environment(sharedGoogleMobileAdsController)
                .environment(sharedStore)
                .environment(sharedConfigurationService)
                .task {
                    #if DEBUG
                    isDebugOn = true
                    #endif

                    sharedGoogleMobileAdsController.start()

                    sharedStore.open(
                        groupID: Secret.groupID,
                        productIDs: [Secret.productID]
                    ) {
                        isSubscribeOn = $0.contains {
                            $0.id == Secret.productID
                        }
                        if !isSubscribeOn {
                            isICloudOn = false
                        }
                    }
                }
        }
    }
}
