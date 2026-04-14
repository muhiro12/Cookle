import Foundation
import MHPlatformCore
import SwiftData

/// Builds model containers and contexts used by Cookle.
public enum ModelContainerFactory {
    private enum MeasurementConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
    }

    /// Returns the shared model container configuration.
    public static func shared() throws -> ModelContainer {
        try makeModelContainer()
    }

    /// Creates the model container used by the main app and validates migrated data.
    @preconcurrency
    public static func appContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        logger: MHLogger? = nil
    ) throws -> ModelContainer {
        let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
        let legacyURL = Database.legacyURL
        let currentURL = Database.url
        let fileManager: FileManager = .default
        let migrationOutcome = try prepareStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            cloudKitDatabase: cloudKitDatabase,
            logger: logger
        )
        logMigrationOutcome(
            migrationOutcome,
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            logger: logger
        )
        let currentContainer = try makeModelContainer(
            cloudKitDatabase: cloudKitDatabase
        )
        let cleanupOutcome = try cleanupLegacyStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )
        logCleanupOutcome(
            cleanupOutcome,
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            logger: logger
        )
        logger?.notice(
            "store prep finished",
            metadata: [
                "duration_ms": durationMilliseconds(
                    since: storePreparationStartedAt
                ).description
            ]
        )
        return currentContainer
    }

    /// Returns a `ModelContext` backed by the shared container.
    public static func sharedContext() throws -> ModelContext {
        .init(try shared())
    }

    static func makeModelContainer(
        url: URL? = nil,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
    ) throws -> ModelContainer {
        if let url {
            return try ModelContainer(
                for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
                migrationPlan: CookleMigrationPlan.self,
                configurations: .init(
                    url: url,
                    cloudKitDatabase: cloudKitDatabase
                )
            )
        }
        return try ModelContainer(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                cloudKitDatabase: cloudKitDatabase
            )
        )
    }

    static func validateMigratedDataBeforeDeletingLegacyIfNeeded(
        currentStoreURL: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        legacyURL: URL = Database.legacyURL,
        fileManager: FileManager = .default,
        logger: MHLogger? = nil
    ) throws {
        let validationStartedAt = Date.timeIntervalSinceReferenceDate
        guard legacyURL.standardizedFileURL != currentStoreURL.standardizedFileURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        do {
            let currentContainer = try makeModelContainer(
                url: currentStoreURL,
                cloudKitDatabase: cloudKitDatabase
            )
            logValidationSnapshot(
                .init(
                    currentContainer: currentContainer,
                    legacyURL: legacyURL,
                    currentStoreURL: currentStoreURL,
                    cloudKitDatabase: cloudKitDatabase,
                    fileManager: fileManager,
                    validationStartedAt: validationStartedAt
                ),
                logger: logger
            )
        } catch {
            var metadata = storeStateMetadata(
                fileManager: fileManager,
                legacyURL: legacyURL,
                currentURL: currentStoreURL
            )
            metadata["cloudkit_database"] = String(
                describing: cloudKitDatabase
            )
            logger?.error(
                "store migration validation failed",
                metadata: [
                    "duration_ms": durationMilliseconds(
                        since: validationStartedAt
                    ).description,
                    "error_type": String(describing: type(of: error)),
                    "error": error.localizedDescription
                ]
                .merging(metadata) { _, newValue in
                    newValue
                }
            )
            throw error
        }
    }

    static func durationMilliseconds(
        since startedAt: TimeInterval
    ) -> Int {
        Int(
            (
                Date.timeIntervalSinceReferenceDate
                    - startedAt
            ) * MeasurementConstants.millisecondsPerSecond
        )
    }
}
