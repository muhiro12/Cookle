@testable import CookleLibrary
import Foundation
import Testing

struct DatabaseMigratorCleanupTests {
    @Test
    func removeLegacyStoreFilesIfNeeded_removes_legacy_store_files() throws {
        let fileManager: FileManager = .default
        let baseDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let legacyDirectory = baseDirectory.appendingPathComponent("legacy", isDirectory: true)
        let currentDirectory = baseDirectory.appendingPathComponent("current", isDirectory: true)

        try fileManager.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)

        let storeFileName = "CookleTest.store"
        let legacyURL = legacyDirectory.appendingPathComponent(storeFileName)
        let currentURL = currentDirectory.appendingPathComponent(storeFileName)
        let legacyShmURL = legacyDirectory.appendingPathComponent(
            "\(storeFileName)-shm"
        )
        let legacyWalURL = legacyDirectory.appendingPathComponent(
            "\(storeFileName)-wal"
        )

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyShmURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyWalURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: Data()))

        try DatabaseMigrator.removeLegacyStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(!fileManager.fileExists(atPath: legacyURL.path))
        #expect(!fileManager.fileExists(atPath: legacyShmURL.path))
        #expect(!fileManager.fileExists(atPath: legacyWalURL.path))
        #expect(fileManager.fileExists(atPath: currentURL.path))
    }

    @Test
    func removeLegacyStoreFilesIfNeeded_skips_when_current_store_is_missing() throws {
        let fileManager: FileManager = .default
        let baseDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let legacyDirectory = baseDirectory.appendingPathComponent("legacy", isDirectory: true)
        let currentDirectory = baseDirectory.appendingPathComponent("current", isDirectory: true)

        try fileManager.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)

        let storeFileName = "CookleTest.store"
        let legacyURL = legacyDirectory.appendingPathComponent(storeFileName)

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))

        let outcome = try DatabaseMigrator.removeLegacyStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentDirectory.appendingPathComponent(storeFileName)
        )

        switch outcome {
        case .skipped(.missingCurrentStore):
            break
        case .removed, .skipped:
            Issue.record("Expected missing current skip outcome.")
        }
        #expect(fileManager.fileExists(atPath: legacyURL.path))
    }
}
