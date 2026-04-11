import Foundation

/// Migrates persisted store files between legacy and current locations.
public enum DatabaseMigrator {
    /// Reasons why store migration or cleanup was skipped.
    public enum MigrationSkipReason {
        /// The legacy and current store URLs already point to the same location.
        case sameLocation
        /// The legacy store file does not exist.
        case missingLegacyStore
        /// The current store file does not exist.
        case missingCurrentStore
    }

    /// Outcome produced when copying legacy store files into the current location.
    public enum MigrationOutcome {
        /// Legacy files were copied into the current store location.
        case migrated(
                copiedFileNames: [String],
                removedCurrentFileNames: [String]
             )
        /// Migration was skipped for a safe, known reason.
        case skipped(MigrationSkipReason)
    }

    /// Outcome produced when deleting legacy store files after migration.
    public enum LegacyCleanupOutcome {
        /// Legacy files were removed after the current store was confirmed.
        case removed(fileNames: [String])
        /// Cleanup was skipped for a safe, known reason.
        case skipped(MigrationSkipReason)
    }

    /// Copies legacy store files into the current location when required.
    @discardableResult
    public static func migrateStoreFilesIfNeeded() throws -> MigrationOutcome {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    /// Removes legacy store files after a successful migration.
    @discardableResult
    public static func removeLegacyStoreFilesIfNeeded() throws -> LegacyCleanupOutcome {
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
    ) throws -> MigrationOutcome {
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL else {
            return .skipped(.sameLocation)
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return .skipped(.missingLegacyStore)
        }

        let context = try makeMigrationContext(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )
        return try performMigration(
            context: context,
            fileManager: fileManager,
            validateMigration: validateMigration
        )
    }

    @discardableResult
    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws -> LegacyCleanupOutcome {
        guard legacyURL.standardizedFileURL != currentURL.standardizedFileURL else {
            return .skipped(.sameLocation)
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return .skipped(.missingLegacyStore)
        }
        guard fileManager.fileExists(atPath: currentURL.path) else {
            return .skipped(.missingCurrentStore)
        }

        let legacyFileNames = try migrationCandidateFileNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )

        for fileName in legacyFileNames {
            let fileURL = legacyURL.deletingLastPathComponent().appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }

        return .removed(fileNames: legacyFileNames)
    }
}

private extension DatabaseMigrator {
    struct MigrationContext {
        let currentDirectoryURL: URL
        let legacyDirectoryURL: URL
        let backupDirectoryURL: URL
        let orderedLegacyFileNames: [String]
        let currentFileNames: [String]
        let removedCurrentFileNames: [String]
        let currentURL: URL
    }

    static func makeMigrationContext(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws -> MigrationContext {
        let legacyFileNames = try migrationCandidateFileNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        let currentFileNames = try migrationCandidateFileNames(
            fileManager: fileManager,
            storeURL: currentURL
        )

        return .init(
            currentDirectoryURL: currentURL.deletingLastPathComponent(),
            legacyDirectoryURL: legacyURL.deletingLastPathComponent(),
            backupDirectoryURL: currentURL
                .deletingLastPathComponent()
                .appendingPathComponent(
                    ".database-migration-backup-\(UUID().uuidString)",
                    isDirectory: true
                ),
            orderedLegacyFileNames: orderedCandidateFileNames(
                legacyFileNames,
                baseName: legacyURL.lastPathComponent
            ),
            currentFileNames: currentFileNames,
            removedCurrentFileNames: currentFileNames
                .filter { legacyFileNames.contains($0) == false }
                .sorted(),
            currentURL: currentURL
        )
    }

    static func performMigration(
        context: MigrationContext,
        fileManager: FileManager,
        validateMigration: @Sendable (
            _ currentStoreURL: URL,
            _ copiedFileNames: [String]
        ) throws -> Void
    ) throws -> MigrationOutcome {
        var copiedFileURLs: [URL] = []

        try fileManager.createDirectory(
            at: context.currentDirectoryURL,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: context.backupDirectoryURL,
            withIntermediateDirectories: true
        )

        do {
            for fileName in context.currentFileNames {
                try fileManager.moveItem(
                    at: context.currentDirectoryURL.appendingPathComponent(fileName),
                    to: context.backupDirectoryURL.appendingPathComponent(fileName)
                )
            }

            for fileName in context.orderedLegacyFileNames {
                let destinationURL = context.currentDirectoryURL.appendingPathComponent(fileName)
                try fileManager.copyItem(
                    at: context.legacyDirectoryURL.appendingPathComponent(fileName),
                    to: destinationURL
                )
                copiedFileURLs.append(destinationURL)
            }

            try validateMigration(
                context.currentURL,
                context.orderedLegacyFileNames
            )
            try? fileManager.removeItem(at: context.backupDirectoryURL)
            return .migrated(
                copiedFileNames: context.orderedLegacyFileNames,
                removedCurrentFileNames: context.removedCurrentFileNames
            )
        } catch {
            rollbackMigration(
                fileManager: fileManager,
                copiedFileURLs: copiedFileURLs,
                currentDirectoryURL: context.currentDirectoryURL,
                backupDirectoryURL: context.backupDirectoryURL
            )
            throw error
        }
    }

    static func migrationCandidateFileNames(
        fileManager: FileManager,
        storeURL: URL
    ) throws -> [String] {
        let directoryURL = storeURL.deletingLastPathComponent()
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        let baseName = storeURL.lastPathComponent
        return try fileManager
            .contentsOfDirectory(atPath: directoryURL.path)
            .filter { name in
                name == baseName || name.hasPrefix(baseName + "-")
            }
    }

    static func orderedCandidateFileNames(
        _ fileNames: [String],
        baseName: String
    ) -> [String] {
        fileNames
            .filter { $0 != baseName }
            .sorted()
            + fileNames.filter { $0 == baseName }
    }

    static func rollbackMigration(
        fileManager: FileManager,
        copiedFileURLs: [URL],
        currentDirectoryURL: URL,
        backupDirectoryURL: URL
    ) {
        for copiedFileURL in copiedFileURLs.reversed() {
            try? fileManager.removeItem(at: copiedFileURL)
        }

        guard let backupFileNames = try? fileManager.contentsOfDirectory(
            atPath: backupDirectoryURL.path
        ) else {
            return
        }

        for fileName in backupFileNames {
            let restoredURL = currentDirectoryURL.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: restoredURL.path) {
                try? fileManager.removeItem(at: restoredURL)
            }
            try? fileManager.moveItem(
                at: backupDirectoryURL.appendingPathComponent(fileName),
                to: restoredURL
            )
        }
        try? fileManager.removeItem(at: backupDirectoryURL)
    }
}
