@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("RecipePhotoRemoval")
struct RecipePhotoRemovalTests {
    @Test
    func persistedPhotoBehaviorRemovesUniqueAssetFromRecipe() {
        #expect(
            RecipePhotoRemovalBehavior.persistedPhotoBehavior(
                draftReferenceCount: 1,
                persistedReferenceCountOutsideRecipe: 0
            ) == .removeFromRecipe
        )
    }

    @Test
    func persistedPhotoBehaviorRemovesSharedAssetFromRecipe() {
        #expect(
            RecipePhotoRemovalBehavior.persistedPhotoBehavior(
                draftReferenceCount: 1,
                persistedReferenceCountOutsideRecipe: 1
            ) == .removeFromRecipe
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
    func removePhotoWithOutcome_keepsPhotoAssetWhenItBecomesUnlinked() throws {
        let context = makeTestContext()
        let photoData = makePhotoData("solo")
        let recipe = makeRecipe(
            context: context,
            name: "Solo",
            photos: [photoData]
        )
        let photoObject = try #require(recipe.photoObjects?.first)

        let outcome = RecipeService.removePhotoWithOutcome(
            context: context,
            recipe: recipe,
            photoObject: photoObject
        )
        try context.save()

        let verificationContext = ModelContext(
            context.container
        )
        let photos = try verificationContext.fetch(.photos(.all))
        let remainingPhoto = try #require(photos.first)

        #expect(outcome.effects == [.recipeDataChanged, .notificationPlanChanged])
        #expect((recipe.photoObjects ?? []).isEmpty)
        #expect((recipe.photos ?? []).isEmpty)
        #expect(photos.count == 1)
        #expect(remainingPhoto.data == photoData.data)
        #expect(remainingPhoto.recipes.orEmpty.isEmpty)
        #expect(remainingPhoto.objects.orEmpty.isEmpty)
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
