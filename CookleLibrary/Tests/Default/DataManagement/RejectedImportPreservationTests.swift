@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A refused import must leave the store exactly as it was. Validation runs
// before `DataResetService.deleteAll`, so these tests pin that ordering against
// a populated disk store rather than against an archive value alone.
@MainActor
struct RejectedImportPreservationTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    enum RejectedInput: CaseIterable, Sendable {
        case manifestNotJSON
        case truncatedManifest
        case otherFormat
        case newerSchema
        case duplicateIdentifier
        case duplicateDiaryDay
        case missingReference
        case oversizedManifest
    }

    // Malformed values that a caller could hand to replacement without going
    // through `validatedArchive` first.
    enum RejectedArchiveValue: CaseIterable, Sendable {
        case partialScope
        case duplicateIdentifier
        case duplicateDiaryDay
        case missingReference
        case oversizedPhoto
    }

    @Test(arguments: RejectedInput.allCases)
    func rejected_export_file_leaves_the_existing_store_readable(
        input: RejectedInput
    ) throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        let original = Support.archive()
        try replace(with: original, at: storeURL)
        let before = try storeContent(at: storeURL)

        do {
            let archive = try CookleDataArchiveService.validatedArchive(
                from: try package(for: input),
                calendar: Support.calendar,
                limits: limits(for: input)
            )
            // Never reached for a rejected input. Present so a regression that
            // moved validation after the reset would actually touch the store.
            let context = try makeContext(at: storeURL)
            _ = try CookleDataArchiveService.replaceAll(
                with: archive,
                context: context,
                calendar: Support.calendar
            )
            Issue.record("Expected \(input) to be refused.")
        } catch {
            // A passing preservation check means nothing if the refusal came
            // from an unrelated failure, so pin which layer rejected the input.
            #expect(rejectedAsExpected(error, for: input))
        }

        #expect(try storeContent(at: storeURL) == before)
    }

    @Test(arguments: RejectedArchiveValue.allCases)
    func rejected_archive_value_never_resets_the_store(
        value: RejectedArchiveValue
    ) throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        try replace(with: Support.archive(), at: storeURL)
        let before = try storeContent(at: storeURL)

        let context = try makeContext(at: storeURL)
        do {
            _ = try CookleDataArchiveService.replaceAll(
                with: archive(for: value),
                context: context,
                calendar: Support.calendar,
                limits: limits(for: value)
            )
            Issue.record("Expected \(value) to be refused.")
        } catch {
            #expect(rejectedAsExpected(error, for: value))
        }

        // The reset is the destructive step. Refusing before it means the
        // context never went dirty, so no rollback was needed to survive.
        #expect(context.hasChanges == false)
        #expect(try storeContent(at: storeURL) == before)
    }

    @Test
    func an_accepted_export_file_still_replaces_the_store() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        try replace(with: Support.archive(), at: storeURL)
        let before = try storeContent(at: storeURL)

        let replacement = Support.archive(
            photoPayloads: [Data([Value.replacementPhotoByte])]
        )
        try replace(with: replacement, at: storeURL)

        // Without this the preservation tests above would pass on a
        // replacement path that silently refused everything.
        #expect(try storeContent(at: storeURL) != before)
    }
}

private extension RejectedImportPreservationTests {
    enum Value {
        static let replacementPhotoByte: UInt8 = 99
        static let oversizedPhotoByteCount = 512
        static let tightManifestByteCount = 8
        static let truncationDivisor = 2
        static let newerSchemaVersion = "99.0.0"
    }

    static let baseArchive = Support.archive()

    func rejectedAsExpected(
        _ error: any Error,
        for input: RejectedInput
    ) -> Bool {
        switch input {
        case .manifestNotJSON, .truncatedManifest:
            error is DecodingError
        case .oversizedManifest:
            isResourceLimitError(error)
        case .otherFormat:
            if case .unsupportedFormat = error as? CookleDataArchivePackageError {
                true
            } else {
                false
            }
        case .newerSchema:
            error as? CookleDataArchiveVersionError
                == .newerSchemaVersion(Value.newerSchemaVersion)
        case .duplicateIdentifier:
            archiveError(error).map(isDuplicateIdentifier) ?? false
        case .duplicateDiaryDay:
            archiveError(error).map(isDuplicateDiaryDay) ?? false
        case .missingReference:
            archiveError(error).map(isMissingReference) ?? false
        }
    }

    func rejectedAsExpected(
        _ error: any Error,
        for value: RejectedArchiveValue
    ) -> Bool {
        switch value {
        case .partialScope:
            error as? CookleDataImportError == .replacementRequiresCompleteArchive
        case .duplicateIdentifier:
            archiveError(error).map(isDuplicateIdentifier) ?? false
        case .duplicateDiaryDay:
            archiveError(error).map(isDuplicateDiaryDay) ?? false
        case .missingReference:
            archiveError(error).map(isMissingReference) ?? false
        case .oversizedPhoto:
            isResourceLimitError(error)
        }
    }

    func archiveError(
        _ error: any Error
    ) -> CookleDataArchiveService.ArchiveError? {
        error as? CookleDataArchiveService.ArchiveError
    }

    func isDuplicateIdentifier(
        _ error: CookleDataArchiveService.ArchiveError
    ) -> Bool {
        guard case .duplicateIdentifier = error else {
            return false
        }
        return true
    }

    func isDuplicateDiaryDay(
        _ error: CookleDataArchiveService.ArchiveError
    ) -> Bool {
        guard case .duplicateDiaryDay = error else {
            return false
        }
        return true
    }

    func isMissingReference(
        _ error: CookleDataArchiveService.ArchiveError
    ) -> Bool {
        guard case .missingReference = error else {
            return false
        }
        return true
    }

    func isResourceLimitError(_ error: any Error) -> Bool {
        guard let archiveError = archiveError(error) else {
            return false
        }
        return switch archiveError {
        case .resourceByteCountExceeded, .resourceCountExceeded:
            true
        default:
            false
        }
    }

    func package(for input: RejectedInput) throws -> CookleDataArchivePackage {
        let validPackage = try Support.package()
        switch input {
        case .manifestNotJSON:
            return .init(
                manifestData: Data("not a Cookle export".utf8),
                photoFiles: validPackage.photoFiles
            )
        case .truncatedManifest:
            return .init(
                manifestData: truncated(validPackage.manifestData),
                photoFiles: validPackage.photoFiles
            )
        case .oversizedManifest:
            return validPackage
        case .otherFormat:
            return try Support.package(
                manifest: Support.replacingHeader(
                    Support.manifest(from: validPackage),
                    format: "com.muhiro12.cookle.backup"
                ),
                photoFiles: validPackage.photoFiles
            )
        case .newerSchema:
            return try Support.package(
                manifest: Support.replacingHeader(
                    Support.manifest(from: validPackage),
                    schemaVersion: Value.newerSchemaVersion
                ),
                photoFiles: validPackage.photoFiles
            )
        case .duplicateIdentifier:
            return try Support.unvalidatedPackage(
                from: archive(for: .duplicateIdentifier)
            )
        case .duplicateDiaryDay:
            return try Support.unvalidatedPackage(
                from: archive(for: .duplicateDiaryDay)
            )
        case .missingReference:
            return try Support.unvalidatedPackage(
                from: archive(for: .missingReference)
            )
        }
    }

    func limits(for input: RejectedInput) -> CookleDataArchiveResourceLimits {
        guard input == .oversizedManifest else {
            return .standard
        }
        return ArchiveResourceLimitTestSupport.makeLimits(
            maximumManifestByteCount: Value.tightManifestByteCount
        )
    }

    func limits(for value: RejectedArchiveValue) -> CookleDataArchiveResourceLimits {
        guard value == .oversizedPhoto else {
            return .standard
        }
        return ArchiveResourceLimitTestSupport.makeLimits()
    }

    func archive(for value: RejectedArchiveValue) -> CookleDataArchive {
        let base = Self.baseArchive
        return .init(
            scope: value == .partialScope ? .partial("recipes") : base.scope,
            exportedAt: base.exportedAt,
            ingredients: value == .duplicateIdentifier
                ? base.ingredients + base.ingredients
                : base.ingredients,
            // Dropping the categories the recipe still points at is what makes
            // the reference dangle.
            categories: value == .missingReference ? [] : base.categories,
            photos: value == .oversizedPhoto ? oversizedPhotos(base.photos) : base.photos,
            recipes: base.recipes,
            diaries: value == .duplicateDiaryDay
                ? base.diaries + duplicatedDay(base.diaries)
                : base.diaries
        )
    }

    func oversizedPhotos(
        _ photos: [CookleDataArchive.PhotoRecord]
    ) -> [CookleDataArchive.PhotoRecord] {
        photos.map { photo in
            .init(
                id: photo.id,
                data: Data(
                    repeating: .zero,
                    count: Value.oversizedPhotoByteCount
                ),
                sourceID: photo.sourceID,
                createdTimestamp: photo.createdTimestamp,
                modifiedTimestamp: photo.modifiedTimestamp
            )
        }
    }

    func duplicatedDay(
        _ diaries: [CookleDataArchive.DiaryRecord]
    ) -> [CookleDataArchive.DiaryRecord] {
        diaries.map { diary in
            .init(
                id: diary.id + "-copy",
                date: diary.date,
                objects: diary.objects,
                note: diary.note,
                createdTimestamp: diary.createdTimestamp,
                modifiedTimestamp: diary.modifiedTimestamp
            )
        }
    }

    func truncated(_ data: Data) -> Data {
        data.prefix(data.count / Value.truncationDivisor)
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

    func replace(with archive: CookleDataArchive, at url: URL) throws {
        let context = try makeContext(at: url)
        _ = try DataMaintenanceOperations.replaceAllData(with: archive, context: context)
    }

    // Reopens the store so the comparison reads what actually landed on disk.
    func storeContent(at url: URL) throws -> Data {
        try TestArchiveContent.data(
            storedIn: makeContext(at: url)
        )
    }
}
