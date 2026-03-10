//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import MHLogging
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(.isICloudOn)
    private var isICloudOn
    @AppStorage(.isDebugOn)
    private var isDebugOn
    @AppStorage(.lastLaunchedAppVersion)
    private var lastLaunchedAppVersion

    @State private var bootstrapModel = CookleAppBootstrapModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if let platformEnvironment = bootstrapModel.platformEnvironment {
                    ContentView()
                        .id(isICloudOn)
                        .cooklePlatformEnvironment(platformEnvironment)
                } else {
                    CookleStartupView(
                        failureMessage: bootstrapModel.failureMessage
                    )
                }
            }
            .task(id: isICloudOn) {
                await bootstrapModel.loadEnvironment(
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

extension CookleApp {
    nonisolated static let loggerFactory = MHLoggerFactory.osLogDefault

    nonisolated static func logger(
        category: String,
        source: String = #fileID
    ) -> MHLogger {
        loggerFactory.logger(
            category: category,
            source: source
        )
    }
}
