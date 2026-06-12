import SwiftData

/// Photo use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum PhotoOperations {
    /// Deletes the supplied photo asset and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        photo: Photo
    ) -> MutationOutcome<Void> {
        PhotoService.deleteWithOutcome(
            context: context,
            photo: photo
        )
    }
}
