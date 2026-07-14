import Foundation
import SwiftData

/// Data maintenance use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum DataMaintenanceOperations {
    /// Maximum encoded backup payload accepted for restore.
    nonisolated public static let maximumEncodedArchiveByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumEncodedByteCount
    /// Maximum encoded manifest payload accepted in a version 2 package.
    nonisolated public static let maximumArchiveManifestByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumManifestByteCount
    /// Maximum combined manifest and photo payload accepted in a version 2 package.
    nonisolated public static let maximumArchivePackageByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumPackageByteCount
    /// Maximum individual photo payload accepted in a version 2 package.
    nonisolated public static let maximumArchivePhotoByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumPhotoByteCount
    /// Maximum combined photo payload accepted in a version 2 package.
    nonisolated public static let maximumArchiveAggregatePhotoByteCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumAggregatePhotoByteCount
    /// Maximum photo file count accepted in a version 2 package.
    nonisolated public static let maximumArchivePhotoFileCount: Int =
        CookleDataArchiveResourceLimits.standard.maximumTopLevelRecordCountPerCategory

    /// Encodes the current persisted user data as portable JSON backup data.
    public static func encodedArchive(
        from context: ModelContext,
        calendar: Calendar = .current
    ) throws -> Data {
        try CookleDataArchiveService.encodedArchive(
            from: context,
            calendar: calendar
        )
    }

    /// Builds a version 2 package with photo payloads stored outside its manifest.
    public static func archivePackage(
        from context: ModelContext,
        calendar: Calendar = .current
    ) async throws -> CookleDataArchivePackage {
        try await CookleDataArchiveService.archivePackage(
            from: context,
            calendar: calendar
        )
    }

    /// Decodes and validates JSON backup data before restore confirmation.
    nonisolated public static func validatedArchive(
        from data: Data,
        calendar: Calendar = .current
    ) throws -> CookleDataArchive {
        try CookleDataArchiveService.validatedArchive(
            from: data,
            calendar: calendar
        )
    }

    /// Validates a version 2 package before restore confirmation.
    nonisolated public static func validatedArchive(
        from package: CookleDataArchivePackage,
        calendar: Calendar = .current
    ) throws -> CookleDataArchive {
        try CookleDataArchiveService.validatedArchive(
            from: package,
            calendar: calendar
        )
    }

    /// Replaces current persisted user data with the supplied validated archive.
    public static func restore(
        _ archive: CookleDataArchive,
        context: ModelContext
    ) throws -> CookleDataRestoreSummary {
        try CookleDataArchiveService.restore(
            archive,
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
