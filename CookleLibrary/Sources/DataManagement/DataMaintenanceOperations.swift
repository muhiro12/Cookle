import Foundation
import SwiftData

/// Data maintenance use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum DataMaintenanceOperations {
    /// Encodes the current persisted user data as portable JSON backup data.
    public static func encodedArchive(
        from context: ModelContext
    ) throws -> Data {
        try CookleDataArchiveService.encodedArchive(
            from: context
        )
    }

    /// Decodes and validates JSON backup data before restore confirmation.
    public static func validatedArchive(
        from data: Data
    ) throws -> CookleDataArchive {
        try CookleDataArchiveService.validatedArchive(
            from: data
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
