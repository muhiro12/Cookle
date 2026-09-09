@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct ArchivePersistentStoreTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    enum BackupFormat: CaseIterable, Sendable {
        case legacyJSON
        case package
    }

    @Test(arguments: BackupFormat.allCases)
    func restore_preserves_complete_graph_after_reopening_store(
        format: BackupFormat
    ) async throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let sourceURL = directory.appendingPathComponent("source.sqlite")
        let destinationURL = directory.appendingPathComponent("destination.sqlite")
        let original = originalArchive()
        try restore(original, at: sourceURL)
        let sourceContext = try makeContext(at: sourceURL)
        let archive: CookleDataArchive
        switch format {
        case .legacyJSON:
            let data = try DataMaintenanceOperations.encodedArchive(
                from: sourceContext,
                calendar: Support.calendar
            )
            archive = try DataMaintenanceOperations.validatedArchive(
                from: data,
                calendar: Support.calendar
            )
        case .package:
            let package = try await DataMaintenanceOperations.archivePackage(
                from: sourceContext,
                calendar: Support.calendar
            )
            archive = try DataMaintenanceOperations.validatedArchive(
                from: package,
                calendar: Support.calendar
            )
        }

        try restore(replacementArchive(), at: destinationURL)
        try restore(archive, at: destinationURL)

        let reopenedContext = try makeContext(at: destinationURL)
        let reopenedArchive = try CookleDataArchiveService.makeArchive(
            context: reopenedContext
        )
        #expect(try contentData(reopenedArchive) == contentData(original))
    }

    @Test
    func failed_save_preserves_complete_graph_after_reopening_store() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        let original = originalArchive()
        try restore(original, at: storeURL)

        try attemptFailedReplacement(at: storeURL, original: original)

        let reopenedContext = try makeContext(at: storeURL)
        let reopenedArchive = try CookleDataArchiveService.makeArchive(
            context: reopenedContext
        )
        #expect(try contentData(reopenedArchive) == contentData(original))
    }
}

private extension ArchivePersistentStoreTests {
    enum Value {
        static let photoByteCount = 1_048_576
        static let replacementPhotoByte: UInt8 = 99
    }

    enum SaveError: Error {
        case forcedFailure
    }

    func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    func originalArchive() -> CookleDataArchive {
        Support.archive(
            photoPayloads: [Data(repeating: 1, count: Value.photoByteCount)]
        )
    }

    func replacementArchive() -> CookleDataArchive {
        Support.archive(
            photoPayloads: [Data([Value.replacementPhotoByte])]
        )
    }

    func restore(_ archive: CookleDataArchive, at url: URL) throws {
        let context = try makeContext(at: url)
        _ = try DataMaintenanceOperations.restore(archive, context: context)
    }

    func attemptFailedReplacement(
        at url: URL,
        original: CookleDataArchive
    ) throws {
        let context = try makeContext(at: url)
        var attemptedSave = false
        let failingSave: (ModelContext) throws -> Void = { _ in
            attemptedSave = true
            throw SaveError.forcedFailure
        }
        do {
            _ = try CookleDataArchiveService.restore(
                replacementArchive(),
                context: context,
                calendar: Support.calendar,
                save: failingSave
            )
            Issue.record("Expected the replacement save to fail.")
        } catch SaveError.forcedFailure {
            // Expected.
        }

        #expect(attemptedSave)
        #expect(context.hasChanges == false)
        let restoredArchive = try CookleDataArchiveService.makeArchive(context: context)
        #expect(try contentData(restoredArchive) == contentData(original))
    }

    func contentData(_ archive: CookleDataArchive) throws -> Data {
        // Export time changes on every snapshot; all stored content must match.
        try CookleDataArchiveService.encoder.encode(
            CookleDataArchive(
                formatVersion: archive.formatVersion,
                exportedAt: Support.exportedAt,
                ingredients: archive.ingredients,
                categories: archive.categories,
                photos: archive.photos,
                recipes: archive.recipes,
                diaries: archive.diaries
            )
        )
    }
}
