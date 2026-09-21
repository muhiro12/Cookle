@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A restore that is refused must leave the store exactly as it was. Validation
// runs before `DataResetService.deleteAll`, so these tests pin that ordering
// against a populated disk store rather than against an archive value alone.
@MainActor
struct RejectedRestorePreservationTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    enum RejectedInput: CaseIterable, Sendable {
        case notJSON
        case truncatedJSON
        case unsupportedFormatVersion
        case duplicateIdentifier
        case duplicateDiaryDay
        case missingReference
        case oversizedEncodedData
    }

    // Malformed values that a caller could hand to `restore` without going
    // through `validatedArchive` first.
    enum RejectedArchiveValue: CaseIterable, Sendable {
        case unsupportedFormatVersion
        case duplicateIdentifier
        case duplicateDiaryDay
        case missingReference
        case oversizedPhoto
    }

    @Test(arguments: RejectedInput.allCases)
    func rejected_backup_data_leaves_the_existing_store_readable(
        input: RejectedInput
    ) throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        let original = Support.archive()
        try restore(original, at: storeURL)
        let before = try storeContent(at: storeURL)

        do {
            let archive = try CookleDataArchiveService.validatedArchive(
                from: try data(for: input),
                calendar: Support.calendar,
                limits: limits(for: input)
            )
            // Never reached for a rejected input. Present so a regression that
            // moved validation after the reset would actually touch the store.
            let context = try makeContext(at: storeURL)
            _ = try CookleDataArchiveService.restore(
                archive,
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
        try restore(Support.archive(), at: storeURL)
        let before = try storeContent(at: storeURL)

        let context = try makeContext(at: storeURL)
        #expect(throws: CookleDataArchiveService.ArchiveError.self) {
            _ = try CookleDataArchiveService.restore(
                archive(for: value),
                context: context,
                calendar: Support.calendar,
                limits: limits(for: value)
            )
        }

        // The reset is the destructive step. Refusing before it means the
        // context never went dirty, so no rollback was needed to survive.
        #expect(context.hasChanges == false)
        #expect(try storeContent(at: storeURL) == before)
    }

    @Test
    func an_accepted_backup_still_replaces_the_store() throws {
        let directory = try makeDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appendingPathComponent("original.sqlite")
        try restore(Support.archive(), at: storeURL)
        let before = try storeContent(at: storeURL)

        let replacement = Support.archive(
            photoPayloads: [Data([Value.replacementPhotoByte])]
        )
        try restore(replacement, at: storeURL)

        // Without this the preservation tests above would pass on a restore
        // path that silently refused everything.
        #expect(try storeContent(at: storeURL) != before)
    }
}

private extension RejectedRestorePreservationTests {
    enum Value {
        static let replacementPhotoByte: UInt8 = 99
        static let unsupportedFormatVersion = 999
        static let oversizedPhotoByteCount = 512
        static let tightEncodedByteCount = 8
        static let truncationDivisor = 2
    }

    static let baseArchive = Support.archive()

    func rejectedAsExpected(
        _ error: any Error,
        for input: RejectedInput
    ) -> Bool {
        switch input {
        case .notJSON, .truncatedJSON:
            error is DecodingError
        case .oversizedEncodedData:
            isResourceLimitError(error)
        case .unsupportedFormatVersion:
            archiveError(error).map(isUnsupportedFormatVersion) ?? false
        case .duplicateIdentifier:
            archiveError(error).map(isDuplicateIdentifier) ?? false
        case .duplicateDiaryDay:
            archiveError(error).map(isDuplicateDiaryDay) ?? false
        case .missingReference:
            archiveError(error).map(isMissingReference) ?? false
        }
    }

    func archiveError(
        _ error: any Error
    ) -> CookleDataArchiveService.ArchiveError? {
        error as? CookleDataArchiveService.ArchiveError
    }

    func isUnsupportedFormatVersion(
        _ error: CookleDataArchiveService.ArchiveError
    ) -> Bool {
        guard case .unsupportedFormatVersion = error else {
            return false
        }
        return true
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

    func data(for input: RejectedInput) throws -> Data {
        switch input {
        case .notJSON:
            Data("not a Cookle backup".utf8)
        case .truncatedJSON:
            try truncated(
                CookleDataArchiveService.encoder.encode(Support.archive())
            )
        case .oversizedEncodedData:
            try CookleDataArchiveService.encoder.encode(Support.archive())
        case .unsupportedFormatVersion:
            try CookleDataArchiveService.encoder.encode(
                archive(for: .unsupportedFormatVersion)
            )
        case .duplicateIdentifier:
            try CookleDataArchiveService.encoder.encode(
                archive(for: .duplicateIdentifier)
            )
        case .duplicateDiaryDay:
            try CookleDataArchiveService.encoder.encode(
                archive(for: .duplicateDiaryDay)
            )
        case .missingReference:
            try CookleDataArchiveService.encoder.encode(
                archive(for: .missingReference)
            )
        }
    }

    func limits(for input: RejectedInput) -> CookleDataArchiveResourceLimits {
        guard input == .oversizedEncodedData else {
            return .standard
        }
        return ArchiveResourceLimitTestSupport.makeLimits(
            maximumEncodedByteCount: Value.tightEncodedByteCount
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
        return replacing(
            formatVersion: value == .unsupportedFormatVersion
                ? Value.unsupportedFormatVersion
                : base.formatVersion,
            ingredients: value == .duplicateIdentifier
                ? base.ingredients + base.ingredients
                : base.ingredients,
            // Dropping the categories the recipe still points at is what makes
            // the reference dangle.
            categories: value == .missingReference ? [] : base.categories,
            photos: value == .oversizedPhoto ? oversizedPhotos(base.photos) : base.photos,
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

    func replacing(
        formatVersion: Int,
        ingredients: [CookleDataArchive.IngredientRecord],
        categories: [CookleDataArchive.CategoryRecord],
        photos: [CookleDataArchive.PhotoRecord],
        diaries: [CookleDataArchive.DiaryRecord]
    ) -> CookleDataArchive {
        .init(
            formatVersion: formatVersion,
            exportedAt: Self.baseArchive.exportedAt,
            ingredients: ingredients,
            categories: categories,
            photos: photos,
            recipes: Self.baseArchive.recipes,
            diaries: diaries
        )
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

    func restore(_ archive: CookleDataArchive, at url: URL) throws {
        let context = try makeContext(at: url)
        _ = try DataMaintenanceOperations.restore(archive, context: context)
    }

    // Reopens the store so the comparison reads what actually landed on disk.
    func storeContent(at url: URL) throws -> Data {
        let archive = try CookleDataArchiveService.makeArchive(
            context: try makeContext(at: url)
        )
        return try CookleDataArchiveService.encoder.encode(
            CookleDataArchive(
                formatVersion: archive.formatVersion,
                // Export time moves on every snapshot; content must not.
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
