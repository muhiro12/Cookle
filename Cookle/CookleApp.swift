//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import AppIntents
import MHPlatform
import SwiftData
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(.isICloudOn)
    private var isICloudOn
    @AppStorage(.isDebugOn)
    private var isDebugOn
    @AppStorage(.lastLaunchedAppVersion)
    private var lastLaunchedAppVersion

    private let sharedAssembly: CookleAppAssembly
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .cookleAppDependencies(sharedAssembly.dependencies)
                .mhAppRuntimeBootstrap(sharedAssembly.bootstrap)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        sharedAssembly = Self.makeAssembly(
            cloudKitDatabase: cloudKitDatabase
        )
        startupLogger.notice("startup dependencies ready")

        #if DEBUG
        isDebugOn = true
        #endif

        CookleShortcuts.updateAppShortcutParameters()

        registerAppIntentDependencies()
        updateLastLaunchedVersion()
        startupLogger.notice("startup wiring finished")
    }
}

private extension CookleApp {
    @MainActor
    static func makeAssembly(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) -> CookleAppAssembly {
        do {
            return try CookleAppAssembly.live(
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }
    }

    func registerAppIntentDependencies() {
        // Provide dependencies for AppIntents entity queries.
        let modelContainerForDependency = sharedAssembly.dependencies.modelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let recipeActionServiceForDependency = sharedAssembly.dependencies.recipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = sharedAssembly.dependencies.diaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = sharedAssembly.dependencies.tagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = sharedAssembly.dependencies.settingsActionService
        AppDependencyManager.shared.add { settingsActionServiceForDependency }
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
