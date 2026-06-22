//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import MHPlatform
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.isDebugOn)
    private var isDebugOn
    @AppStorage(\.lastLaunchedAppVersion, default: "")
    private var lastLaunchedAppVersion

    @State private var bootstrapModel = CookleAppBootstrapModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if let appAssembly = bootstrapModel.appAssembly {
                    ContentView()
                        .id(isICloudOn)
                        .cookleAppAssembly(appAssembly)
                } else {
                    CookleStartupView(
                        failureMessage: bootstrapModel.failureMessage
                    )
                }
            }
            .task(id: isICloudOn) {
                await bootstrapModel.loadAssembly(
                    isICloudOn: isICloudOn
                )
            }
        }
    }

    init() {
        #if DEBUG
        isDebugOn = true
        #endif

        updateLastLaunchedVersion()
    }

    func updateLastLaunchedVersion() {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }
}
