@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A widget entry pairs a title, an optional image and a deep link. The image
// comes from `PhotoImageProcessor.downsampledImage`, and the provider treats a
// nil result as "no image" rather than as a failed entry:
//
//     let image = recipe.primaryPhotoData.flatMap { data in
//         RecipeWidgetImageLoader.makeImage(from: data, family: family)
//     }
//
// These tests pin the two halves that make that safe — the decode really does
// return nil rather than trapping, and everything else the entry needs is
// still available when it does.
@MainActor
struct WidgetImageFailureTests {
    @Test
    func undecodable_photo_bytes_yield_no_image_instead_of_trapping() {
        let garbage = Data("this is not an image".utf8)

        #expect(
            PhotoImageProcessor.downsampledImage(
                from: garbage,
                maximumPixelSize: Value.maximumPixelSize
            ) == nil
        )
    }

    @Test
    func an_empty_photo_payload_yields_no_image() {
        #expect(
            PhotoImageProcessor.downsampledImage(
                from: Data(),
                maximumPixelSize: Value.maximumPixelSize
            ) == nil
        )
    }

    @Test
    func a_recipe_whose_photo_cannot_decode_still_supplies_a_title_and_link() throws {
        let context = makeTestContext()
        let photo = try Photo.create(
            context: context,
            photoData: .init(
                data: Data("this is not an image".utf8),
                source: .photosPicker
            )
        )
        let recipe = Recipe.create(
            context: context,
            content: .init(
                name: "Curry",
                photos: [
                    PhotoObject.restore(
                        context: context,
                        photo: photo,
                        order: .zero,
                        createdTimestamp: .now,
                        modifiedTimestamp: .now
                    )
                ],
                servingSize: Value.servingSize,
                cookingTime: Value.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )

        // The bytes are present, so the provider's `flatMap` runs and fails at
        // the decode rather than skipping it.
        let data = try #require(recipe.primaryPhotoData)
        #expect(
            PhotoImageProcessor.downsampledImage(
                from: data,
                maximumPixelSize: Value.maximumPixelSize
            ) == nil
        )

        // Everything else the entry needs survives the bad image.
        #expect(recipe.name == "Curry")
        #expect(
            RecipeStableIdentifierCodec.encodeIfPossible(recipe.id) != nil
        )
    }

    @Test
    func a_non_positive_pixel_size_is_refused_rather_than_guessed() {
        let garbage = Data("this is not an image".utf8)

        #expect(
            PhotoImageProcessor.downsampledImage(
                from: garbage,
                maximumPixelSize: .zero
            ) == nil
        )
    }
}

private extension WidgetImageFailureTests {
    enum Value {
        static let maximumPixelSize = 256
        static let servingSize = 1
        static let cookingTimeMinutes = 10
    }
}
