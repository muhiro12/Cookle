@testable import CookleLibrary
import Foundation
import Testing

struct DatabaseMigratorTests {
    @Test
    func migrateStoreFilesIfNeeded_copies_legacy_store_files_when_current_missing() throws {
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

        try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(fileManager.fileExists(atPath: currentURL.path))
        #expect(fileManager.fileExists(atPath: currentDirectory.appendingPathComponent("\(storeFileName)-shm").path))
        #expect(fileManager.fileExists(atPath: currentDirectory.appendingPathComponent("\(storeFileName)-wal").path))
        #expect(fileManager.fileExists(atPath: legacyURL.path))
        #expect(fileManager.fileExists(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-shm").path))
        #expect(fileManager.fileExists(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-wal").path))
    }

    @Test
    func migrateStoreFilesIfNeeded_overwrites_current_when_legacy_exists() throws {
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

        let legacyData = Data("legacy".utf8)
        let currentData = Data("current".utf8)
        #expect(fileManager.createFile(atPath: legacyURL.path, contents: legacyData))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: currentData))
        #expect(fileManager.createFile(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-wal").path, contents: legacyData))
        #expect(fileManager.createFile(atPath: currentDirectory.appendingPathComponent("\(storeFileName)-wal").path, contents: currentData))

        try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        let migratedStoreData = try Data(contentsOf: currentURL)
        let migratedWalData = try Data(contentsOf: currentDirectory.appendingPathComponent("\(storeFileName)-wal"))
        #expect(migratedStoreData == legacyData)
        #expect(migratedWalData == legacyData)
        #expect(try Data(contentsOf: legacyURL) == legacyData)
    }

    @Test
    func migrateStoreFilesIfNeeded_removes_stale_current_sidecars_not_in_legacy() throws {
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
        let currentWalURL = currentDirectory.appendingPathComponent("\(storeFileName)-wal")
        let currentShmURL = currentDirectory.appendingPathComponent("\(storeFileName)-shm")

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        let legacyData = Data("legacy".utf8)
        let staleCurrentData = Data("stale-current".utf8)
        #expect(fileManager.createFile(atPath: legacyURL.path, contents: legacyData))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: staleCurrentData))
        #expect(fileManager.createFile(atPath: currentWalURL.path, contents: staleCurrentData))
        #expect(fileManager.createFile(atPath: currentShmURL.path, contents: staleCurrentData))

        try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(try Data(contentsOf: currentURL) == legacyData)
        #expect(!fileManager.fileExists(atPath: currentWalURL.path))
        #expect(!fileManager.fileExists(atPath: currentShmURL.path))
    }

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

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-shm").path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-wal").path, contents: Data()))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: Data()))

        try DatabaseMigrator.removeLegacyStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(!fileManager.fileExists(atPath: legacyURL.path))
        #expect(!fileManager.fileExists(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-shm").path))
        #expect(!fileManager.fileExists(atPath: legacyDirectory.appendingPathComponent("\(storeFileName)-wal").path))
        #expect(fileManager.fileExists(atPath: currentURL.path))
    }
}
