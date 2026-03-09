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

    private let platformEnvironment: CooklePlatformEnvironment
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .cooklePlatformEnvironment(platformEnvironment)
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        platformEnvironment = Self.makePlatformEnvironment(
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
    static func makePlatformEnvironment(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) -> CooklePlatformEnvironment {
        do {
            return try CooklePlatformEnvironmentFactory.live(
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }
    }

    func registerAppIntentDependencies() {
        // Provide dependencies for AppIntents entity queries.
        let modelContainerForDependency = platformEnvironment.modelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let recipeActionServiceForDependency = platformEnvironment.recipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = platformEnvironment.diaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = platformEnvironment.tagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = platformEnvironment.settingsActionService
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
