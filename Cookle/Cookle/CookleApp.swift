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
                secrets["adUnitIDDev"]!
                #else
                secrets["adUnitID"]!
                #endif
            }()
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .cookleEnvironment(
                    groupID: secrets["groupID"]!,
                    productID: secrets["productID"]!,
                    googleMobileAds: {
                        sharedGoogleMobileAdsController.buildView($0)
                    },
                    licenseList: {            
                        LicenseListView()
                    }
                )
        }
    }
}
