import Foundation

public enum DatabaseMigrator {
    public static func migrateStoreFilesIfNeeded() throws {
        try migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    public static func replaceCurrentStoreFilesWithLegacy() throws {
        try replaceCurrentStoreFilesWithLegacy(
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
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }
        guard !fileManager.fileExists(atPath: currentURL.path) else {
            return
        }

        try copyStoreFiles(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            overwriteCurrent: false
        )
    }

    static func replaceCurrentStoreFilesWithLegacy(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) throws {
        guard fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        try copyStoreFiles(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL,
            overwriteCurrent: true
        )
    }
}

private extension DatabaseMigrator {
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
        let baseName = legacyURL.lastPathComponent

        let candidateNames = try fileManager.contentsOfDirectory(atPath: legacyDirectoryURL.path)
            .filter { name in
                name == baseName || name.hasPrefix(baseName + "-")
            }
        guard !candidateNames.isEmpty else {
            return
        }

        let orderedCandidateNames = candidateNames
            .filter { $0 != baseName }
            .sorted()
            + [baseName]
        var copiedDestinationURLs = [URL]()

        do {
            for candidateName in orderedCandidateNames {
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
}
