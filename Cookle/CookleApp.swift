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
import SwiftUI
import UIKit

@main
struct CookleApp: App {
    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

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

        CookleShortcuts.updateAppShortcutParameters()

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
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
                    },
                    appIntents: {
                        ShortcutsLink()
                            .shortcutsLinkStyle(.automaticOutline)
                    }
                )
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
