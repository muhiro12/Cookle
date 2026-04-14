import Testing

@testable import Cookle

@MainActor
@Suite("RecipePhotoRemovalBehavior")
struct RecipePhotoRemovalBehaviorTests {
    @Test
    func persistedPhotoBehaviorDeletesOrphanedAsset() {
        #expect(
            RecipePhotoRemovalBehavior.persistedPhotoBehavior(
                draftReferenceCount: 1,
                persistedReferenceCountOutsideRecipe: 0
            ) == .deletePhoto
        )
    }

    @Test
    func persistedPhotoBehaviorDetachesSharedAsset() {
        #expect(
            RecipePhotoRemovalBehavior.persistedPhotoBehavior(
                draftReferenceCount: 1,
                persistedReferenceCountOutsideRecipe: 1
            ) == .detachFromRecipe
        )
    }

    @Test
    func persistedPhotoBehaviorDetachesWhenDraftKeepsAnotherReference() {
        #expect(
            RecipePhotoRemovalBehavior.persistedPhotoBehavior(
                draftReferenceCount: 2,
                persistedReferenceCountOutsideRecipe: 0
            ) == .detachFromRecipe
        )
    }
}
