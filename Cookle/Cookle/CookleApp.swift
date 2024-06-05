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
                .secret(secrets)
                .googleMobileAds {
                    sharedGoogleMobileAdsController.buildView($0)
                }
                .licenseList {
                    LicenseListView()
                }
        }
    }
}
