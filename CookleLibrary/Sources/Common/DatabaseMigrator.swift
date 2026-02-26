import Foundation

public enum DatabaseMigrator {
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
        guard legacyURL != currentURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        let legacyStoreCandidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        guard !legacyStoreCandidateNames.isEmpty else {
            return
        }

        try fileManager.createDirectory(
            at: currentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let currentStoreCandidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: currentURL
        )

        // Make retries deterministic by clearing current candidates first.
        try removeStoreFilesIfExists(
            fileManager: fileManager,
            storeURL: currentURL,
            candidateNames: mergedCandidateNames(
                primaryCandidateNames: legacyStoreCandidateNames,
                secondaryCandidateNames: currentStoreCandidateNames
            )
        )

        try copyStoreFiles(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            overwriteCurrent: true
        )
    }

    static func removeLegacyStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        guard legacyURL != currentURL else {
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        let candidateNames = try storeCandidateNames(
            fileManager: fileManager,
            storeURL: legacyURL
        )
        guard !candidateNames.isEmpty else {
            return
        }

        try removeStoreFilesIfExists(
            fileManager: fileManager,
            storeURL: legacyURL,
            candidateNames: candidateNames
        )
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
