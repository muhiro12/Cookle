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
import TipKit

@main
struct CookleApp: App {
    @AppStorage(.isICloudOn)
    private var isICloudOn
    @AppStorage(.isDebugOn)
    private var isDebugOn
    @AppStorage(.lastLaunchedAppVersion)
    private var lastLaunchedAppVersion

    private let sharedModelContainer: ModelContainer
    private let sharedAppRuntime: MHAppRuntime
    private let sharedConfigurationService: ConfigurationService
    private let sharedRouteInbox: MHObservableDeepLinkInbox
    private let sharedNotificationService: NotificationService
    private let sharedTipController: CookleTipController
    private let sharedRecipeActionService: RecipeActionService
    private let sharedDiaryActionService: DiaryActionService
    private let sharedTagActionService: TagActionService
    private let sharedSettingsActionService: SettingsActionService
    private let startupLogger = Self.logger(category: "AppStartup")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .modelContainer(sharedModelContainer)
                .environment(sharedAppRuntime)
                .environment(sharedConfigurationService)
                .environment(sharedRouteInbox)
                .environment(sharedNotificationService)
                .environment(sharedTipController)
                .environment(sharedRecipeActionService)
                .environment(sharedDiaryActionService)
                .environment(sharedTagActionService)
                .environment(sharedSettingsActionService)
                .task {
                    performStartupTasks()
                }
        }
    }

    @MainActor
    init() {
        startupLogger.notice("app startup began")
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        sharedModelContainer = Self.makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )

        sharedAppRuntime = Self.makeAppRuntime()
        sharedConfigurationService = .init()
        sharedRouteInbox = .init()
        sharedNotificationService = .init(
            modelContainer: sharedModelContainer,
            routeInbox: sharedRouteInbox
        )
        sharedTipController = .init()
        sharedRecipeActionService = .init(
            notificationService: sharedNotificationService
        )
        sharedDiaryActionService = .init()
        sharedTagActionService = .init()
        sharedSettingsActionService = .init(
            notificationService: sharedNotificationService
        )
        startupLogger.notice("startup dependencies ready")

        CookleShortcuts.updateAppShortcutParameters()

        registerAppIntentDependencies()
        configureTipController()
        updateLastLaunchedVersion()
        startupLogger.notice("startup wiring finished")
    }
}

private extension CookleApp {
    static var adUnitID: String {
        #if DEBUG
        Secret.adUnitIDDev
        #else
        Secret.adUnitID
        #endif
    }

    @MainActor
    static func makeAppRuntime() -> MHAppRuntime {
        .init(
            configuration: .init(
                subscriptionProductIDs: [Secret.productID],
                subscriptionGroupID: Secret.groupID,
                nativeAdUnitID: adUnitID,
                preferencesSuiteName: CookleSharedPreferences.appGroupIdentifier,
                showsLicenses: true
            )
        )
    }

    static func makeModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) -> ModelContainer {
        do {
            return try ModelContainerFactory.appContainer(
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }
    }

    func performStartupTasks() {
        #if DEBUG
        isDebugOn = true
        #endif

        sharedAppRuntime.startIfNeeded()
    }

    func registerAppIntentDependencies() {
        // Provide dependencies for AppIntents entity queries.
        let modelContainerForDependency = sharedModelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let recipeActionServiceForDependency = sharedRecipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = sharedDiaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = sharedTagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = sharedSettingsActionService
        AppDependencyManager.shared.add { settingsActionServiceForDependency }
    }

    func configureTipController() {
        do {
            try sharedTipController.configureIfNeeded()
        } catch {
            assertionFailure(error.localizedDescription)
        }
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

    @discardableResult
    nonisolated static func requestReviewIfNeeded(
        policy: MHReviewPolicy,
        source: String = #fileID
    ) async -> MHReviewRequestOutcome {
        await MHReviewRequester.requestIfNeeded(policy: policy) { outcome in
            let logger = logger(
                category: "ReviewFlow",
                source: source
            )

            switch outcome {
            case .requested:
                logger.notice("review request invoked")
            case .skippedInvalidLotteryRange:
                logger.warning("review request skipped because the lottery range was invalid")
            case .skippedNoForegroundScene:
                logger.info("review request skipped because no foreground scene was available")
            case .unsupportedPlatform:
                logger.info("review request skipped because the platform is unsupported")
            case .skippedByPolicy:
                break
            }
        }
    }
}
