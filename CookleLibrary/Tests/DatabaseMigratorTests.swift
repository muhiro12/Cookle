@testable import CookleLibrary
import Foundation
import Testing

struct DatabaseMigratorTests {
    @Test
    func migrateStoreFilesIfNeeded_moves_legacy_store_files_when_current_missing() throws {
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

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-shm").path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-wal").path, contents: Data()))

        DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(fileManager.fileExists(atPath: currentURL.path))
        #expect(fileManager.fileExists(atPath: currentDirectory.appendingPathComponent("\(storeFileName)-shm").path))
        #expect(fileManager.fileExists(atPath: currentDirectory.appendingPathComponent("\(storeFileName)-wal").path))
    }

    @Test
    func migrateStoreFilesIfNeeded_does_nothing_when_current_exists() throws {
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

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: Data()))

        DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(fileManager.fileExists(atPath: legacyURL.path))
        #expect(fileManager.fileExists(atPath: currentURL.path))
    }
}
