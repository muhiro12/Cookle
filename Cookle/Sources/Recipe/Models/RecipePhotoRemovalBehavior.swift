enum RecipePhotoRemovalBehavior: Equatable {
    case detachFromRecipe
    case deletePhoto

    static func persistedPhotoBehavior(
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
