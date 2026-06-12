import SwiftData

/// Data maintenance use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum DataMaintenanceOperations {
    /// Deletes every persisted Cookle model and returns follow-up hints.
    public static func deleteAllWithOutcome(
        context: ModelContext
    ) throws -> MutationOutcome<Void> {
        try DataResetService.deleteAllWithOutcome(
            context: context
        )
    }
}
