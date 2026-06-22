@testable import CookleLibrary
import Foundation
import Testing

struct DatabaseMigratorTests {
    private enum ValidationError: Error {
        case failed
    }

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
        let legacyShmURL = legacyDirectory.appendingPathComponent(
            "\(storeFileName)-shm"
        )
        let legacyWalURL = legacyDirectory.appendingPathComponent(
            "\(storeFileName)-wal"
        )
        let currentShmURL = currentDirectory.appendingPathComponent(
            "\(storeFileName)-shm"
        )
        let currentWalURL = currentDirectory.appendingPathComponent(
            "\(storeFileName)-wal"
        )

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyShmURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyWalURL.path, contents: Data()))

        try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        #expect(fileManager.fileExists(atPath: currentURL.path))
        #expect(fileManager.fileExists(atPath: currentShmURL.path))
        #expect(fileManager.fileExists(atPath: currentWalURL.path))
        #expect(fileManager.fileExists(atPath: legacyURL.path))
        #expect(fileManager.fileExists(atPath: legacyShmURL.path))
        #expect(fileManager.fileExists(atPath: legacyWalURL.path))
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
        let legacyWalURL = legacyDirectory.appendingPathComponent(
            "\(storeFileName)-wal"
        )
        let currentWalURL = currentDirectory.appendingPathComponent(
            "\(storeFileName)-wal"
        )

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        let legacyData = Data("legacy".utf8)
        let currentData = Data("current".utf8)
        #expect(fileManager.createFile(atPath: legacyURL.path, contents: legacyData))
        #expect(fileManager.createFile(atPath: currentURL.path, contents: currentData))
        #expect(fileManager.createFile(atPath: legacyWalURL.path, contents: legacyData))
        #expect(fileManager.createFile(atPath: currentWalURL.path, contents: currentData))

        try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        let migratedStoreData = try Data(contentsOf: currentURL)
        let migratedWalData = try Data(contentsOf: currentWalURL)
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
    func migrateStoreFilesIfNeeded_removes_copied_files_when_validation_fails() throws {
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
        let legacyWalURL = legacyDirectory.appendingPathComponent("\(storeFileName)-wal")
        let currentWalURL = currentDirectory.appendingPathComponent("\(storeFileName)-wal")

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: legacyURL.path, contents: Data()))
        #expect(fileManager.createFile(atPath: legacyWalURL.path, contents: Data()))

        #expect(throws: ValidationError.failed) {
            try DatabaseMigrator.migrateStoreFilesIfNeeded(
                fileManager: fileManager,
                legacyURL: legacyURL,
                currentURL: currentURL
            ) { _, _ in
                throw ValidationError.failed
            }
        }

        #expect(fileManager.fileExists(atPath: legacyURL.path))
        #expect(fileManager.fileExists(atPath: legacyWalURL.path))
        #expect(!fileManager.fileExists(atPath: currentURL.path))
        #expect(!fileManager.fileExists(atPath: currentWalURL.path))
    }

    @Test
    func migrateStoreFilesIfNeeded_skips_when_legacy_store_is_missing() throws {
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
        let currentShmURL = currentDirectory.appendingPathComponent("\(storeFileName)-shm")
        let currentWalURL = currentDirectory.appendingPathComponent("\(storeFileName)-wal")
        let currentData = Data("current".utf8)

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: currentURL.path, contents: currentData))
        #expect(fileManager.createFile(atPath: currentShmURL.path, contents: currentData))
        #expect(fileManager.createFile(atPath: currentWalURL.path, contents: currentData))

        let outcome = try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: legacyURL,
            currentURL: currentURL
        )

        switch outcome {
        case .skipped(.missingLegacyStore):
            break
        case .migrated, .skipped:
            Issue.record("Expected missing legacy skip outcome.")
        }
        #expect(try Data(contentsOf: currentURL) == currentData)
        #expect(try Data(contentsOf: currentShmURL) == currentData)
        #expect(try Data(contentsOf: currentWalURL) == currentData)
    }

    @Test
    func migrateStoreFilesIfNeeded_skips_when_store_locations_match() throws {
        let fileManager: FileManager = .default
        let baseDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )

        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        let storeURL = baseDirectory.appendingPathComponent("CookleTest.store")
        let walURL = baseDirectory.appendingPathComponent("CookleTest.store-wal")
        let legacyData = Data("legacy".utf8)

        defer {
            try? fileManager.removeItem(at: baseDirectory)
        }

        #expect(fileManager.createFile(atPath: storeURL.path, contents: legacyData))
        #expect(fileManager.createFile(atPath: walURL.path, contents: legacyData))

        let outcome = try DatabaseMigrator.migrateStoreFilesIfNeeded(
            fileManager: fileManager,
            legacyURL: storeURL,
            currentURL: storeURL
        )

        switch outcome {
        case .skipped(.sameLocation):
            break
        case .migrated, .skipped:
            Issue.record("Expected same location skip outcome.")
        }
        #expect(try Data(contentsOf: storeURL) == legacyData)
        #expect(try Data(contentsOf: walURL) == legacyData)
    }
}
