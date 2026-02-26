//
//  CookleApp.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/20.
//

import AppIntents
import GoogleMobileAdsWrapper
import LicenseListWrapper
import OSLog
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
    private static let migrationTraceKeyword = "COOKLE_MIGRATION_TRACE"
    private static let migrationLogger: Logger = .init(#file)

    init() {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = CooklePreferences.bool(for: .isICloudOn)
            ? .automatic
            : .none
        let cloudKitDatabaseDescription = String(describing: cloudKitDatabase)

        Self.traceNotice("app migration setup started cloudKitDatabase=\(cloudKitDatabaseDescription)")
        Self.traceNotice("store paths current=\(Database.url.path) legacy=\(Database.legacyURL.path)")

        do {
            Self.traceNotice("step=1 migrateStoreFilesIfNeeded begin")
            try DatabaseMigrator.migrateStoreFilesIfNeeded()
            Self.traceNotice("step=1 migrateStoreFilesIfNeeded end")

            Self.traceNotice("step=2 makeModelContainer begin")
            let modelContainer = try Self.makeCurrentModelContainer(
                cloudKitDatabase: cloudKitDatabase
            )
            Self.traceNotice("step=2 makeModelContainer end")

            Self.traceNotice("step=3 validateMigratedDataBeforeDeletingLegacyIfNeeded begin")
            try Self.validateMigratedDataBeforeDeletingLegacyIfNeeded(
                currentContainer: modelContainer,
                cloudKitDatabase: cloudKitDatabase
            )
            Self.traceNotice("step=3 validateMigratedDataBeforeDeletingLegacyIfNeeded end")

            Self.traceNotice("step=4 removeLegacyStoreFilesIfNeeded begin")
            try DatabaseMigrator.removeLegacyStoreFilesIfNeeded()
            Self.traceNotice("step=4 removeLegacyStoreFilesIfNeeded end")

            sharedModelContainer = modelContainer
        } catch {
            Self.traceError("app migration setup failed error=\(String(describing: error))")
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
    static func makeCurrentModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        try .init(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                cloudKitDatabase: cloudKitDatabase
            )
        )
    }

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

    static func validateMigratedDataBeforeDeletingLegacyIfNeeded(
        currentContainer: ModelContainer,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase
    ) throws {
        let fileManager: FileManager = .default

        Self.traceNotice("validating migrated data started")
        guard Database.legacyURL != Database.url else {
            Self.traceNotice("validation skipped because legacy and current are identical")
            return
        }
        guard fileManager.fileExists(atPath: Database.legacyURL.path) else {
            Self.traceNotice("validation skipped because legacy store does not exist")
            return
        }

        let legacyContainer = try makeModelContainer(
            url: Database.legacyURL,
            cloudKitDatabase: cloudKitDatabase
        )
        let legacyObjectCounts = try objectCounts(in: legacyContainer.mainContext)
        let currentObjectCounts = try objectCounts(in: currentContainer.mainContext)
        Self.traceNotice(
            "validation counts legacy=[\(legacyObjectCounts.summary)] current=[\(currentObjectCounts.summary)]"
        )
        guard currentObjectCounts.hasMatchingRecipeAndDiaryCounts(as: legacyObjectCounts) else {
            Self.traceError("validation failed because recipe/diary counts mismatched")
            throw MigrationValidationError.recipeAndDiaryCountMismatch(
                legacyObjectCounts: legacyObjectCounts,
                currentObjectCounts: currentObjectCounts
            )
        }
        Self.traceNotice("validation succeeded")
    }

    static func objectCounts(in context: ModelContext) throws -> MigrationObjectCounts {
        try .init(
            recipeCount: count(in: context, Recipe.self),
            diaryCount: count(in: context, Diary.self),
            categoryCount: count(in: context, Category.self),
            ingredientCount: count(in: context, Ingredient.self),
            photoCount: count(in: context, Photo.self)
        )
    }

    static func count<Model: PersistentModel>(
        in context: ModelContext,
        _: Model.Type
    ) throws -> Int {
        let fetchDescriptor: FetchDescriptor<Model> = .init()
        return try context.fetchCount(fetchDescriptor)
    }

    static func traceNotice(_ message: String) {
        let traceMessage = "\(migrationTraceKeyword) \(message)"
        migrationLogger.notice("\(traceMessage, privacy: .public)")
        MigrationTraceStore.append(traceMessage)
    }

    static func traceError(_ message: String) {
        let traceMessage = "\(migrationTraceKeyword) \(message)"
        migrationLogger.error("\(traceMessage, privacy: .public)")
        MigrationTraceStore.append(traceMessage)
    }
}

private struct MigrationObjectCounts {
    let recipeCount: Int
    let diaryCount: Int
    let categoryCount: Int
    let ingredientCount: Int
    let photoCount: Int

    nonisolated func hasMatchingRecipeAndDiaryCounts(as legacyObjectCounts: Self) -> Bool {
        recipeCount == legacyObjectCounts.recipeCount
            && diaryCount == legacyObjectCounts.diaryCount
    }

    nonisolated var summary: String {
        """
        recipe=\(recipeCount), diary=\(diaryCount), category=\(categoryCount), \
        ingredient=\(ingredientCount), photo=\(photoCount)
        """
    }
}

private enum MigrationValidationError: LocalizedError {
    case recipeAndDiaryCountMismatch(
            legacyObjectCounts: MigrationObjectCounts,
            currentObjectCounts: MigrationObjectCounts
         )

    var errorDescription: String? {
        switch self {
        case .recipeAndDiaryCountMismatch(let legacyObjectCounts, let currentObjectCounts):
            return """
            Migrated store validation failed. \
            legacy[\(legacyObjectCounts.summary)] \
            current[\(currentObjectCounts.summary)]
            """
        }
    }
}
