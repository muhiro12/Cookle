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
    private struct StoreLoadRequest: Equatable {
        let isICloudOn: Bool
        let retryCount: Int
    }

    @UIApplicationDelegateAdaptor(CookleNotificationAppDelegate.self)
    private var notificationAppDelegate

    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.isDebugOn)
    private var isDebugOn
    @AppStorage(\.lastLaunchedAppVersion, default: "")
    private var lastLaunchedAppVersion

    @State private var bootstrapModel: CookleAppBootstrapModel
    @State private var retryCount = 0

    var body: some Scene {
        WindowGroup {
            let request = StoreLoadRequest(isICloudOn: isICloudOn, retryCount: retryCount)

            Group {
                if let appAssembly = bootstrapModel.appAssembly {
                    rootView(appAssembly: appAssembly)
                } else {
                    CookleStartupView(
                        failureMessage: bootstrapModel.failureMessage,
                        isSwitchingICloud: bootstrapModel.hasLoadedAssembly,
                        openWithoutICloud: request.isICloudOn ? { isICloudOn = false } : nil
                    ) {
                        retryCount += 1
                    }
                }
            }
            .mhTheme(.standard)
            .task(id: request) {
                // `init()` already assembled for the stored setting; only a
                // real toggle needs the store reopened.
                if !bootstrapModel.isAssembled(forICloudSetting: request.isICloudOn) {
                    await bootstrapModel.loadAssembly(isICloudOn: request.isICloudOn)
                }
            }
            .onChange(of: bootstrapModel.appAssembly?.services.notificationService) {
                notificationAppDelegate.notificationService = bootstrapModel.appAssembly?.services.notificationService
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
        if let domainName = Bundle.main.bundleIdentifier {
            CooklePreferences.migrateSuggestionNotificationMode(domainName: domainName)
        }
        let model = CookleAppBootstrapModel()
        model.loadAssemblySynchronously()
        _bootstrapModel = State(wrappedValue: model)
        notificationAppDelegate.notificationService = model.appAssembly?.services.notificationService

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
            .id(ObjectIdentifier(appAssembly))
            .cookleAppAssembly(appAssembly)
    }

    func updateLastLaunchedVersion() {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }
}
