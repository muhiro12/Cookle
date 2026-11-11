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
    @UIApplicationDelegateAdaptor(CookleNotificationAppDelegate.self)
    private var notificationAppDelegate

    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(\.lastLaunchedAppVersion, default: "")
    private var lastLaunchedAppVersion

    @State private var bootstrapModel: CookleAppBootstrapModel

    var body: some Scene {
        WindowGroup {
            sceneContent
                .mhTheme(.standard)
                .environment(bootstrapModel.activeEditors)
                .onChange(of: isICloudSyncRequested, initial: true) {
                    bootstrapModel.reloadAssemblyIfNeeded()
                }
                .onChange(of: bootstrapModel.activeEditors.isEditing) {
                    bootstrapModel.reloadAssemblyIfNeeded()
                }
        }
    }

    @ViewBuilder private var sceneContent: some View {
        if let appAssembly = bootstrapModel.appAssembly {
            rootView(appAssembly: appAssembly)
        } else {
            CookleStartupView(
                failureMessage: bootstrapModel.failureMessage,
                isSwitchingICloud: bootstrapModel.hasLoadedAssembly,
                openWithoutICloud: recoveryAction
            ) {
                bootstrapModel.reloadAssembly()
            }
        }
    }

    private var isICloudSyncRequested: Bool {
        #if DEBUG
        false
        #else
        isSubscribeOn && isICloudOn
        #endif
    }

    private var recoveryAction: (() -> Void)? {
        guard isICloudSyncRequested else {
            return nil
        }
        return {
            isICloudOn = false
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
        _bootstrapModel = State(wrappedValue: model)
        model.start(notificationAppDelegate: notificationAppDelegate)

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
