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
import SwiftData
import SwiftUI

@main
struct CookleApp: App {
    @AppStorage(.isSubscribeOn) private var isSubscribeOn
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn
    @AppStorage(.lastLaunchedAppVersion) private var lastLaunchedAppVersion

    private let sharedGoogleMobileAdsController: GoogleMobileAdsController
    private let sharedModelContainer: ModelContainer
    private let sharedStore: Store
    private let sharedConfigurationService: ConfigurationService
    private let sharedNotificationService: NotificationService

    init() {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none

        do {
            try DatabaseMigrator.migrateStoreFilesIfNeeded()

            var modelContainer = try Self.makeModelContainer(
                url: Database.url,
                cloudKitDatabase: cloudKitDatabase
            )

            if try Self.shouldRecoverLegacyStore(
                currentContainer: modelContainer,
                cloudKitDatabase: cloudKitDatabase
            ) {
                try DatabaseMigrator.replaceCurrentStoreFilesWithLegacy()
                modelContainer = try Self.makeModelContainer(
                    url: Database.url,
                    cloudKitDatabase: cloudKitDatabase
                )
            }

            sharedModelContainer = modelContainer
        } catch {
            fatalError("Failed to prepare data store: \(error.localizedDescription)")
        }

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
        sharedConfigurationService = .init()
        sharedNotificationService = .init(modelContainer: sharedModelContainer)

        CookleShortcuts.updateAppShortcutParameters()

        // Provide dependencies for AppIntents entity queries
        let modelContainerForDependency = sharedModelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }

        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lastLaunchedAppVersion = currentAppVersion
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(isICloudOn)
                .modelContainer(sharedModelContainer)
                .environment(sharedGoogleMobileAdsController)
                .environment(sharedStore)
                .environment(sharedConfigurationService)
                .environment(sharedNotificationService)
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

                    await sharedNotificationService.synchronizeScheduledSuggestions()
                }
        }
    }
}

private extension CookleApp {
    static func makeModelContainer(
        url: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        try .init(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                url: url,
                cloudKitDatabase: cloudKitDatabase
            )
        )
    }

    static func shouldRecoverLegacyStore(
        currentContainer: ModelContainer,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> Bool {
        let fileManager: FileManager = .default
        guard Database.legacyURL != Database.url else {
            return false
        }
        guard fileManager.fileExists(atPath: Database.legacyURL.path) else {
            return false
        }
        guard try !containsUserData(in: currentContainer) else {
            return false
        }

        let legacyContainer: ModelContainer
        do {
            legacyContainer = try makeModelContainer(
                url: Database.legacyURL,
                cloudKitDatabase: cloudKitDatabase
            )
        } catch {
            return false
        }

        return try containsUserData(in: legacyContainer)
    }

    static func containsUserData(in container: ModelContainer) throws -> Bool {
        let context = container.mainContext
        return try hasAnyObjects(in: context, Recipe.self)
            || hasAnyObjects(in: context, Diary.self)
            || hasAnyObjects(in: context, Category.self)
            || hasAnyObjects(in: context, Ingredient.self)
            || hasAnyObjects(in: context, Photo.self)
    }

    static func hasAnyObjects<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Bool {
        var descriptor: FetchDescriptor<Model> = .init()
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }
}
