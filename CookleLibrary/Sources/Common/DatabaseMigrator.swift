import Foundation
import MHPlatform

/// Migrates persisted store files between legacy and current locations.
public enum DatabaseMigrator {
    /// Copies legacy store files into the current location when required.
    public static func migrateStoreFilesIfNeeded() throws {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    /// Removes legacy store files after a successful migration.
    public static func removeLegacyStoreFilesIfNeeded() throws {
        try removeLegacyStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    static func migrateStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        let plan = MHStoreMigrationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        _ = try MHStoreMigrator.migrateIfNeeded(
            plan: plan,
            fileManager: fileManager
        )
    }

    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        let plan = MHStoreMigrationPlan(
            legacyStoreURL: legacyURL,
            currentStoreURL: currentURL
        )
        _ = try MHStoreMigrator.removeLegacyStoreFilesIfNeeded(
            plan: plan,
            fileManager: fileManager
        )
    }
}
