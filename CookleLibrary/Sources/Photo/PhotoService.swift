import SwiftData

/// Internal photo asset collaborator used by public Operations.
@preconcurrency
@MainActor
enum PhotoService {
    /// Deletes the supplied photo asset and returns follow-up hints.
    static func deleteWithOutcome(
        context: ModelContext,
        photo: Photo
    ) -> MutationOutcome<Void> {
        context.delete(photo)
        return .init(
            value: (),
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }
}
