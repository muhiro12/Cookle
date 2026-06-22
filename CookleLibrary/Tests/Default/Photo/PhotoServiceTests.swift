@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct PhotoServiceTests {
    let context = makeTestContext()

    @Test
    func delete_photo_removes_linked_photo_rows_but_keeps_recipes() throws {
        let sharedPhoto = sharedPhotoData()
        let firstRecipe = makeRecipe(
            name: "First",
            cookingTime: 10,
            photoData: sharedPhoto
        )
        let secondRecipe = makeRecipe(
            name: "Second",
            cookingTime: 15,
            photoData: sharedPhoto
        )
        let photo = try #require(
            context.fetch(.photos(.all)).first
        )

        let outcome = PhotoService.deleteWithOutcome(
            context: context,
            photo: photo
        )
        try context.save()

        #expect(outcome.effects.contains(.recipeDataChanged))
        #expect(outcome.effects.contains(.notificationPlanChanged))
        #expect(try context.fetchCount(FetchDescriptor<Photo>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<PhotoObject>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 2)
        #expect(firstRecipe.orderedPhotos.isEmpty)
        #expect(secondRecipe.orderedPhotos.isEmpty)
    }
}

private extension PhotoServiceTests {
    func sharedPhotoData() -> PhotoData {
        .init(
            data: Data("shared-photo".utf8),
            source: .photosPicker
        )
    }

    func makeRecipe(
        name: String,
        cookingTime: Int,
        photoData: PhotoData
    ) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [
                    PhotoObject.create(
                        context: context,
                        photoData: photoData,
                        order: 1
                    )
                ],
                servingSize: 1,
                cookingTime: cookingTime,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }
}
