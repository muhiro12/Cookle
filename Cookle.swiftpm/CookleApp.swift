//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(.isDebugOn) private var isDebugOn

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    isDebugOn = true
                }
                .googleMobileAds {
                    Text("GoogleMobileAds \($0)")
                }
        }
    }
}
