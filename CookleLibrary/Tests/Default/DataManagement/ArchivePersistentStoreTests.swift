@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct ArchivePersistentStoreTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    /// How an exported file reaches the destination store.
    enum ImportMethod: CaseIterable, Sendable {
        /// Replaces a populated store.
        case replace
        /// Merges into an empty store, as when moving to a new device.
        case mergeIntoEmptyStore
    }

    @Test(arguments: ImportMethod.allCases)
    func import_preserves_complete_graph_after_reopening_store(
        method: ImportMethod
    ) async throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let sourceURL = directory.appendingPathComponent("source.sqlite")
        let destinationURL = directory.appendingPathComponent("destination.sqlite")
        let original = originalArchive()
        try replace(with: original, at: sourceURL)
        let sourceContext = try makeContext(at: sourceURL)
        let package = try await DataMaintenanceOperations.archivePackage(
            from: sourceContext,
            calendar: Support.calendar
        )
        let archive = try DataMaintenanceOperations.validatedArchive(
            from: package,
            calendar: Support.calendar
        )

        switch method {
        case .replace:
            try replace(with: replacementArchive(), at: destinationURL)
            try replace(with: archive, at: destinationURL)
        case .mergeIntoEmptyStore:
            let context = try makeContext(at: destinationURL)
            let review = try DataMaintenanceOperations.importReview(
                for: archive,
                context: context,
                calendar: Support.calendar
            )
            #expect(review.isCurrentDataEmpty)
            #expect(review.hasConflicts == false)
            _ = try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: .init(),
                context: context
            )
        }

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
        try replace(with: original, at: storeURL)

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

    func replace(with archive: CookleDataArchive, at url: URL) throws {
        let context = try makeContext(at: url)
        _ = try DataMaintenanceOperations.replaceAllData(with: archive, context: context)
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
            _ = try CookleDataArchiveService.replaceAll(
                with: replacementArchive(),
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
        let currentArchive = try CookleDataArchiveService.makeArchive(context: context)
        #expect(try contentData(currentArchive) == contentData(original))
    }

    func contentData(_ archive: CookleDataArchive) throws -> Data {
        // Export time changes on every snapshot; all stored content must match.
        try TestArchiveContent.data(of: archive)
    }
}
