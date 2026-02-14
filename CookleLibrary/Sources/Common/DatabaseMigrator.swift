import Foundation

public enum DatabaseMigrator {
    public static func migrateStoreFilesIfNeeded() {
        migrateStoreFilesIfNeeded(
            fileManager: .default,
            legacyURL: Database.legacyURL,
            currentURL: Database.url
        )
    }

    static func migrateStoreFilesIfNeeded(
        fileManager: FileManager,
        legacyURL: URL,
        currentURL: URL
    ) {
        guard fileManager.fileExists(atPath: legacyURL.path),
              !fileManager.fileExists(atPath: currentURL.path) else {
            return
        }

        do {
            try fileManager.createDirectory(
                at: currentURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let legacyDirectoryURL = legacyURL.deletingLastPathComponent()
            let baseName = legacyURL.lastPathComponent

            let candidateNames = try fileManager.contentsOfDirectory(atPath: legacyDirectoryURL.path)
                .filter { name in
                    name == baseName || name.hasPrefix(baseName + "-")
                }

            for candidateName in candidateNames {
                let sourceURL = legacyDirectoryURL.appendingPathComponent(candidateName)
                let destinationURL = currentURL.deletingLastPathComponent().appendingPathComponent(candidateName)
                do {
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    if !fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    }
                }
            }
        } catch {
            assertionFailure("Store migration failed: \(error.localizedDescription)")
        }
    }
}
