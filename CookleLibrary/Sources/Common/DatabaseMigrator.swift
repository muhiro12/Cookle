import Foundation
import OSLog

public enum DatabaseMigrator {
    private static let migrationTraceKeyword = "COOKLE_MIGRATION_TRACE"
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier ?? "CookleLibrary",
        category: "DatabaseMigrator"
    )

    public static func migrateStoreFilesIfNeeded() throws {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

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
        traceNotice(
            "migrateStoreFilesIfNeeded started legacyPath=\(legacyURL.path) currentPath=\(currentURL.path)"
        )

        guard legacyURL != currentURL else {
            traceNotice("migrateStoreFilesIfNeeded skipped because legacy and current are identical")
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            traceNotice("migrateStoreFilesIfNeeded skipped because legacy store does not exist")
            return
        }

        let legacyStoreCandidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        let legacyStoreCandidateDescription = legacyStoreCandidateNames.joined(separator: ",")
        traceNotice(
            "legacy store candidates count=\(legacyStoreCandidateNames.count) names=\(legacyStoreCandidateDescription)"
        )
        guard !legacyStoreCandidateNames.isEmpty else {
            traceNotice("migrateStoreFilesIfNeeded skipped because no legacy candidates were found")
            return
        }

        try fileManager.createDirectory(
            at: currentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        traceNotice(
            "ensured current parent directory exists path=\(currentURL.deletingLastPathComponent().path)"
        )

        let currentStoreCandidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: currentURL
        )
        let currentStoreCandidateDescription = currentStoreCandidateNames.joined(separator: ",")
        let currentStoreCandidateCount = currentStoreCandidateNames.count
        let currentCandidatesMessage =
            "current candidates before cleanup count=\(currentStoreCandidateCount) " +
            "names=\(currentStoreCandidateDescription)"
        traceNotice(currentCandidatesMessage)

        // Make retries deterministic by clearing current candidates first.
        let mergedStoreCandidateNames = mergedCandidateNames(
            primaryCandidateNames: legacyStoreCandidateNames,
            secondaryCandidateNames: currentStoreCandidateNames
        )
        let mergedStoreCandidateDescription = mergedStoreCandidateNames.joined(separator: ",")
        let mergedStoreCandidateCount = mergedStoreCandidateNames.count
        let mergedCandidatesMessage =
            "removing current candidates before copy count=\(mergedStoreCandidateCount) " +
            "names=\(mergedStoreCandidateDescription)"
        traceNotice(mergedCandidatesMessage)
        try removeStoreFilesIfExists(
            fileManager: fileManager,
            storeURL: currentURL,
            candidateNames: mergedStoreCandidateNames
        )

        try copyStoreFiles(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            overwriteCurrent: true
        )
        traceNotice("migrateStoreFilesIfNeeded completed successfully")
    }

    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        traceNotice("removeLegacyStoreFilesIfNeeded started legacyPath=\(legacyURL.path)")

        guard legacyURL != currentURL else {
            traceNotice("removeLegacyStoreFilesIfNeeded skipped because legacy and current are identical")
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            traceNotice("removeLegacyStoreFilesIfNeeded skipped because legacy store does not exist")
            return
        }

        let candidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        let candidateDescription = candidateNames.joined(separator: ",")
        traceNotice(
            "legacy store candidates to remove count=\(candidateNames.count) names=\(candidateDescription)"
        )
        guard !candidateNames.isEmpty else {
            traceNotice("removeLegacyStoreFilesIfNeeded skipped because no legacy candidates were found")
            return
        }

        try removeStoreFilesIfExists(
            fileManager: fileManager,
            storeURL: legacyURL,
            candidateNames: candidateNames
        )
        traceNotice("removeLegacyStoreFilesIfNeeded completed successfully")
    }
}

private extension DatabaseMigrator {
    static func traceNotice(_ message: String) {
        let traceMessage = "\(migrationTraceKeyword) \(message)"
        logger.notice("\(traceMessage, privacy: .public)")
        MigrationTraceStore.append(traceMessage)
    }
}

private extension DatabaseMigrator {
    static func storeCandidateNames(
        fileManager: FileManager,
        storeURL: URL
    ) throws -> [String] {
        let storeDirectoryURL = storeURL.deletingLastPathComponent()
        let baseName = storeURL.lastPathComponent
        let candidateNames = try fileManager.contentsOfDirectory(atPath: storeDirectoryURL.path)
            .filter { name in
                name == baseName || name.hasPrefix(baseName + "-")
            }
        return candidateNames
            .filter { $0 != baseName }
            .sorted()
            + [baseName]
    }

    static func copyStoreFiles(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL,
        overwriteCurrent: Bool
    ) throws {
        try fileManager.createDirectory(
            at: currentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let legacyDirectoryURL = legacyURL.deletingLastPathComponent()
        let currentDirectoryURL = currentURL.deletingLastPathComponent()

        let candidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        guard !candidateNames.isEmpty else {
            return
        }

        var copiedDestinationURLs = [URL]()

        do {
            for candidateName in candidateNames {
                let sourceURL = legacyDirectoryURL.appendingPathComponent(candidateName)
                let destinationURL = currentDirectoryURL.appendingPathComponent(candidateName)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    if overwriteCurrent {
                        try fileManager.removeItem(at: destinationURL)
                    } else {
                        continue
                    }
                }

                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                copiedDestinationURLs.append(destinationURL)
            }
        } catch {
            for destinationURL in copiedDestinationURLs.reversed() {
                try? fileManager.removeItem(at: destinationURL)
            }
            throw error
        }
    }

    static func removeStoreFilesIfExists(
        fileManager: FileManager,
        storeURL: URL,
        candidateNames: [String]
    ) throws {
        let storeDirectoryURL = storeURL.deletingLastPathComponent()

        for candidateName in candidateNames {
            let fileURL = storeDirectoryURL.appendingPathComponent(candidateName)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                continue
            }
            try fileManager.removeItem(at: fileURL)
        }
    }

    static func mergedCandidateNames(
        primaryCandidateNames: [String],
        secondaryCandidateNames: [String]
    ) -> [String] {
        Array(
            Set(primaryCandidateNames).union(secondaryCandidateNames)
        )
        .sorted()
    }
}
