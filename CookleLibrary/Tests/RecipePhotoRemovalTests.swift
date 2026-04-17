@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("RecipePhotoRemoval")
struct RecipePhotoRemovalTests {
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
    func removePhotoWithOutcome_keepsSharedPhotoAssetWhenAnotherReferenceExists() throws {
        let context = makeTestContext()
        let sharedPhotoData = makePhotoData("shared")
        let firstRecipe = makeRecipe(
            context: context,
            name: "First",
            photos: [sharedPhotoData]
        )
        let secondRecipe = makeRecipe(
            context: context,
            name: "Second",
            photos: [sharedPhotoData]
        )
        let firstPhotoObject = try #require(firstRecipe.photoObjects?.first)

        let outcome = RecipeService.removePhotoWithOutcome(
            context: context,
            recipe: firstRecipe,
            photoObject: firstPhotoObject
        )

        #expect(outcome.effects == [.recipeDataChanged, .notificationPlanChanged])
        #expect((firstRecipe.photoObjects ?? []).isEmpty)
        #expect((firstRecipe.photos ?? []).isEmpty)
        #expect((secondRecipe.photoObjects ?? []).count == 1)
        #expect((secondRecipe.photos ?? []).count == 1)
        #expect(try context.fetch(.photos(.all)).count == 1)
    }

    @Test
    func removePhotoWithOutcome_deletesPhotoAssetWhenItBecomesOrphaned() throws {
        let context = makeTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Solo",
            photos: [makePhotoData("solo")]
        )
        let photoObject = try #require(recipe.photoObjects?.first)

        let outcome = RecipeService.removePhotoWithOutcome(
            context: context,
            recipe: recipe,
            photoObject: photoObject
        )

        #expect(outcome.effects == [.recipeDataChanged, .notificationPlanChanged])
        #expect((recipe.photoObjects ?? []).isEmpty)
        #expect((recipe.photos ?? []).isEmpty)
        #expect(try context.fetch(.photos(.all)).isEmpty)
    }
}

private extension RecipePhotoRemovalTests {
    enum TestValues {
        static let cookingTimeMinutes = 10
    }

    func makeRecipe(
        context: ModelContext,
        name: String,
        photos: [PhotoData]
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: name,
            photos: zip(
                photos.indices,
                photos
            ).map { index, photoData in
                PhotoObject.create(
                    context: context,
                    photoData: photoData,
                    order: index + 1
                )
            },
            servingSize: 1,
            cookingTime: TestValues.cookingTimeMinutes,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    func makePhotoData(
        _ identifier: String
    ) -> PhotoData {
        .init(
            data: Data(identifier.utf8),
            source: .photosPicker
        )
    }
}
