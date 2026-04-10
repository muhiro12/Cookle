import Foundation
import MHPlatformCore

/// Migrates persisted store files between legacy and current locations.
public enum DatabaseMigrator {
    /// Copies legacy store files into the current location when required.
    @discardableResult
    public static func migrateStoreFilesIfNeeded() throws -> MHStoreMigrationOutcome {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    /// Removes legacy store files after a successful migration.
    @discardableResult
    public static func removeLegacyStoreFilesIfNeeded() throws -> MHStoreLegacyCleanupOutcome {
        try removeLegacyStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    @discardableResult
    static func migrateStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        validateMigration: @Sendable (
            _ currentStoreURL: URL,
            _ copiedFileNames: [String]
        ) throws -> Void = { _, _ in
            // Intentionally empty.
        }
    ) throws -> MHStoreMigrationOutcome {
        let plan = MHStoreMigrationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        return try MHStoreMigrator.migrateIfNeeded(
            plan: plan,
            fileManager: fileManager,
            validateMigration: validateMigration
        )
    }

    @discardableResult
    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws -> MHStoreLegacyCleanupOutcome {
        let plan = MHStoreMigrationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        return try MHStoreMigrator.removeLegacyStoreFilesIfNeeded(
            plan: plan,
            fileManager: fileManager
        )
    }
}
