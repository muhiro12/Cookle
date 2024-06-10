//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import SwiftUI
import CooklePlaygrounds
import CooklePackages

@main
struct CookleApp: App {
    private let sharedGoogleMobileAdsController: GoogleMobileAdsController

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .cookleEnvironment(
                    groupID: Secret.groupID,
                    productID: Secret.productID,
                    googleMobileAds: {
                        sharedGoogleMobileAdsController.buildNativeAd($0)
                    },
                    licenseList: {
                        LicenseListView()
                    }
                )
                .task {
                    sharedGoogleMobileAdsController.start()
                }
        }
    }
}
