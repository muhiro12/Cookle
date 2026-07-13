@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipePhotoDisplayTests {
    @Test
    func orderedPhotos_preferPhotoObjectOrderOverFlattenedRelationOrder() throws {
        let context = makeTestContext()
        let secondPhotoObject = try PhotoObject.create(
            context: context,
            photoData: makePhotoData("second"),
            order: 2
        )
        let firstPhotoObject = try PhotoObject.create(
            context: context,
            photoData: makePhotoData("first"),
            order: 1
        )
        let recipe = makeRecipe(
            context: context,
            photos: [
                secondPhotoObject,
                firstPhotoObject
            ]
        )

        #expect(recipe.photos?.map(\.data) == [data("second"), data("first")])
        #expect(recipe.orderedPhotoObjects.map(\.order) == [1, 2])
        #expect(recipe.orderedPhotos.map(\.data) == [data("first"), data("second")])
        #expect(recipe.primaryPhotoData == data("first"))
    }

    @Test
    func orderedPhotos_fallBackToFlattenedPhotosWhenPhotoObjectsAreEmpty() throws {
        let context = makeTestContext()
        let fallbackPhotos = [
            try Photo.create(
                context: context,
                photoData: makePhotoData("first")
            ),
            try Photo.create(
                context: context,
                photoData: makePhotoData("second")
            )
        ]

        #expect(
            RecipePhotoDisplay.orderedPhotos(
                photoObjects: [],
                fallbackPhotos: fallbackPhotos
            )
            .map(\.data) == [data("first"), data("second")]
        )
        #expect(
            RecipePhotoDisplay.primaryPhotoData(
                photoObjects: [],
                fallbackPhotos: fallbackPhotos
            ) == data("first")
        )
    }
}

private extension RecipePhotoDisplayTests {
    enum TestValues {
        static let cookingTimeMinutes = 10
    }

    func makeRecipe(
        context: ModelContext,
        photos: [PhotoObject]
    ) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: "Recipe",
                photos: photos,
                servingSize: 1,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }

    func makePhotoData(
        _ identifier: String
    ) -> PhotoData {
        .init(
            data: data(identifier),
            source: .photosPicker
        )
    }

    func data(
        _ identifier: String
    ) -> Data {
        Data(identifier.utf8)
    }
}
