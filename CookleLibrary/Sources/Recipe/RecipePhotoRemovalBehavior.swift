import Foundation

/// Canonical persisted-photo removal action shared by app surfaces.
public enum RecipePhotoRemovalBehavior: Equatable, Sendable {
    case removeFromRecipe

    public static func persistedPhotoBehavior(
        draftReferenceCount: Int,
        persistedReferenceCountOutsideRecipe: Int
    ) -> Self {
        _ = draftReferenceCount
        _ = persistedReferenceCountOutsideRecipe
        return .removeFromRecipe
    }
}
