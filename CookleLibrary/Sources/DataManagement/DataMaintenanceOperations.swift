import Foundation
import SwiftData

/// Data maintenance use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum DataMaintenanceOperations {
    /// Maximum encoded manifest payload accepted in an export package.
    nonisolated public static let maximumArchiveManifestByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumManifestByteCount
    /// Maximum combined manifest and photo payload accepted in an export package.
    nonisolated public static let maximumArchivePackageByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumPackageByteCount
    /// Maximum individual photo payload accepted in an export package.
    nonisolated public static let maximumArchivePhotoByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumPhotoByteCount
    /// Maximum combined photo payload accepted in an export package.
    nonisolated public static let maximumArchiveAggregatePhotoByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumAggregatePhotoByteCount
    /// Maximum photo file count accepted in an export package.
    nonisolated public static let maximumArchivePhotoFileCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumTopLevelRecordCountPerCategory

    /// Builds an export package of every current record, with photo payloads
    /// stored outside its manifest.
    public static func archivePackage(
        from context: ModelContext,
        calendar: Calendar = .current
    ) async throws -> CookleDataArchivePackage {
        try await CookleDataArchiveService.archivePackage(
            from: context,
            calendar: calendar
        )
    }

    /// Validates an export package and returns its current-schema content.
    ///
    /// - Throws: `CookleDataArchiveVersionError.newerSchemaVersion` when a newer
    ///   Cookle wrote the file, or a validation error for any other invalid file.
    nonisolated public static func validatedArchive(
        from package: CookleDataArchivePackage,
        calendar: Calendar = .current
    ) throws -> CookleDataArchive {
        try CookleDataArchiveService.validatedArchive(
            from: package,
            calendar: calendar
        )
    }

    /// Reviews how merging a validated archive into current data would go,
    /// without changing the store.
    ///
    /// - Throws: `CookleDataImportError.duplicateCurrentDiaryDays` when a day the
    ///   file touches already has several diaries, which must be merged first.
    public static func importReview(
        for archive: CookleDataArchive,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> CookleDataImportReview {
        try CookleDataImportService.review(
            for: archive,
            context: context,
            calendar: calendar
        )
    }

    /// Merges a validated archive into current data using a choice for every conflict.
    ///
    /// Nothing changes unless the review still matches current data and the
    /// choices resolve every conflict. All changes are saved together. Use
    /// `CookleDataImportSelections.updatingMatchingData(for:)` to update every
    /// match with the file's content instead of choosing per conflict.
    ///
    /// - Throws: `CookleDataImportError.reviewChanged` with a rebuilt review when
    ///   current data or the archive changed, `CookleDataImportError.invalidSelections`
    ///   for missing or invalid choices, or the save error after rolling back.
    public static func importArchive(
        _ archive: CookleDataArchive,
        review: CookleDataImportReview,
        selections: CookleDataImportSelections,
        context: ModelContext
    ) throws -> CookleDataImportSummary {
        try CookleDataImportService.apply(
            archive,
            review: review,
            selections: selections,
            context: context
        )
    }

    /// Captures every current record and the file before destructive replacement.
    /// Unlike a merge review, this includes data the file does not reference.
    public static func replacementReview(
        for archive: CookleDataArchive,
        context: ModelContext
    ) throws -> CookleDataReplacementReview {
        try CookleDataArchiveService.validate(archive, calendar: .current, limits: .standard)
        return .init(
            archiveIdentity: try CookleDataImportSnapshotBuilder(archive: archive).archiveIdentity(),
            currentDataIdentity: try CookleDataImportSnapshotBuilder(
                archive: CookleDataArchiveService.makeArchive(context: context)
            ).archiveIdentity(includingExportDate: false)
        )
    }

    /// Replaces data only while the complete library and file still match the review.
    /// A changed review leaves all records untouched and requires a new confirmation.
    public static func replaceAllData(
        with archive: CookleDataArchive,
        review: CookleDataReplacementReview,
        context: ModelContext
    ) throws -> CookleDataReplacementSummary {
        guard context.hasChanges == false else {
            throw CookleDataImportError.pendingChanges
        }
        guard try replacementReview(for: archive, context: context) == review else {
            throw CookleDataImportError.replacementReviewChanged
        }
        return try replaceAllData(with: archive, context: context)
    }

    /// Replaces all current data with a validated complete-library archive.
    ///
    /// - Throws: `CookleDataImportError.replacementRequiresCompleteArchive` when
    ///   the archive's scope is not `.all`, a validation error, or the save error
    ///   after rolling back. Every failure leaves current data unchanged.
    public static func replaceAllData(
        with archive: CookleDataArchive,
        context: ModelContext
    ) throws -> CookleDataReplacementSummary {
        try CookleDataArchiveService.replaceAll(
            with: archive,
            context: context
        )
    }

    /// Deletes every persisted Cookle model and returns follow-up hints.
    public static func deleteAllWithOutcome(
        context: ModelContext
    ) throws -> MutationOutcome<Void> {
        try DataResetService.deleteAllWithOutcome(
            context: context
        )
    }
}
