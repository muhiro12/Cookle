import SwiftData

/// Photo asset workflows shared by the app and maintenance surfaces.
@preconcurrency
@MainActor
public enum PhotoService {
    /// Deletes the supplied photo asset and returns follow-up hints.
    public static func deleteWithOutcome(
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
