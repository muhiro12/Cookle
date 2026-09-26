//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import MHPlatform
import MHUI
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.isDebugOn)
    private var isDebugOn
    @AppStorage(\.lastLaunchedAppVersion, default: "")
    private var lastLaunchedAppVersion

    @State private var bootstrapModel: CookleAppBootstrapModel

    var body: some Scene {
        WindowGroup {
            Group {
                if let appAssembly = bootstrapModel.appAssembly {
                    rootView(appAssembly: appAssembly)
                } else {
                    CookleStartupView(
                        failureMessage: bootstrapModel.failureMessage
                    ) {
                        Task {
                            await bootstrapModel.loadAssembly(
                                isICloudOn: isICloudOn
                            )
                        }
                    }
                }
            }
            .mhTheme(.standard)
            .task(id: isICloudOn) {
                // `init()` already assembled for the stored setting; only a
                // real toggle needs the store reopened.
                guard !bootstrapModel.isAssembled(forICloudSetting: isICloudOn) else {
                    return
                }
                await bootstrapModel.loadAssembly(
                    isICloudOn: isICloudOn
                )
            }
        }
    }

    @MainActor
    init() {
        // Navigation bars, text inputs, and tab bars read these UIKit defaults
        // when they are created, so they have to be configured before any
        // scene builds its hierarchy.
        MHTheme.standard.configureNativeAppearance()

        // Must happen here, not in the scene: an App Intent can launch this
        // process without a scene, and its dependencies have to be registered
        // before `perform()` runs.
        let model = CookleAppBootstrapModel()
        model.loadAssemblySynchronously()
        _bootstrapModel = State(wrappedValue: model)

        #if DEBUG
        isDebugOn = !CookleCaptureConfiguration.isEnabled
        #endif

        updateLastLaunchedVersion()
    }

    @ViewBuilder
    func rootView(appAssembly: CookleAppAssembly) -> some View {
        #if DEBUG
        if CookleCaptureConfiguration.isEnabled {
            ContentView()
                .cooklePreviewAppAssembly(appAssembly)
        } else {
            liveRootView(appAssembly: appAssembly)
        }
        #else
        liveRootView(appAssembly: appAssembly)
        #endif
    }

    func liveRootView(appAssembly: CookleAppAssembly) -> some View {
        ContentView()
            .id(isICloudOn)
            .cookleAppAssembly(appAssembly)
    }

    func updateLastLaunchedVersion() {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }
}
