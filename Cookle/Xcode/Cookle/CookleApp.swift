//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import CooklePackages
import CooklePlaygrounds
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn

    private let sharedGoogleMobileAdsController: GoogleMobileAdsController
    private let sharedStore: Store

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

        sharedStore = .init()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .cookleEnvironment(
                    googleMobileAds: {
                        sharedGoogleMobileAdsController.buildNativeAd($0)
                    },
                    licenseList: {
                        LicenseListView()
                    },
                    storeKit: {
                        sharedStore.buildSubscriptionSection()
                    }
                )
                .task {
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
