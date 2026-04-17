import Foundation

/// Canonical persisted-photo removal decisions shared by app surfaces.
public enum RecipePhotoRemovalBehavior: Equatable, Sendable {
    case detachFromRecipe
    case deletePhoto

    public static func persistedPhotoBehavior(
        draftReferenceCount: Int,
        persistedReferenceCountOutsideRecipe: Int
    ) -> Self {
        let remainingReferenceCount = max(
            .zero,
            draftReferenceCount - 1
        ) + max(
            .zero,
            persistedReferenceCountOutsideRecipe
        )

        if remainingReferenceCount == .zero {
            return .deletePhoto
        }

        return .detachFromRecipe
    }
}
