import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct RecipePhotoMutationTests {
    @Test
    func remove_keepsSharedPhotoAssetWhenAnotherReferenceExists() throws {
        let context = try makeCookleTestContext()
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

        RecipePhotoMutation.remove(
            context: context,
            recipe: firstRecipe,
            photoObject: firstPhotoObject
        )

        #expect((firstRecipe.photoObjects ?? []).isEmpty)
        #expect((firstRecipe.photos ?? []).isEmpty)
        #expect((secondRecipe.photoObjects ?? []).count == 1)
        #expect((secondRecipe.photos ?? []).count == 1)
        #expect(try context.fetch(.photos(.all)).count == 1)
    }

    @Test
    func remove_deletesPhotoAssetWhenItBecomesOrphaned() throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Solo",
            photos: [makePhotoData("solo")]
        )
        let photoObject = try #require(recipe.photoObjects?.first)

        RecipePhotoMutation.remove(
            context: context,
            recipe: recipe,
            photoObject: photoObject
        )

        #expect((recipe.photoObjects ?? []).isEmpty)
        #expect((recipe.photos ?? []).isEmpty)
        #expect(try context.fetch(.photos(.all)).isEmpty)
    }
}

private extension RecipePhotoMutationTests {
    func makeRecipe(
        context: ModelContext,
        name: String,
        photos: [PhotoData]
    ) -> Recipe {
        let defaultServingSize = 1
        let defaultCookingTime = 10

        return Recipe.create(
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
            servingSize: defaultServingSize,
            cookingTime: defaultCookingTime,
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
