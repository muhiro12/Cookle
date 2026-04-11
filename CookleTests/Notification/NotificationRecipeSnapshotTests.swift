import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct NotificationRecipeSnapshotTests {
    @Test
    func make_usesStoredDisplayOrderForPrimaryPhotoData() throws {
        let context = try makeCookleTestContext()
        let secondPhotoObject = PhotoObject.create(
            context: context,
            photoData: makePhotoData("second"),
            order: 2
        )
        let firstPhotoObject = PhotoObject.create(
            context: context,
            photoData: makePhotoData("first"),
            order: 1
        )
        let recipe = Recipe.create(
            context: context,
            name: "Recipe",
            photos: [
                secondPhotoObject,
                firstPhotoObject
            ],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        let snapshot = NotificationRecipeSnapshot.make(
            recipe: recipe
        )

        #expect(recipe.photos?.map(\.data) == [data("second"), data("first")])
        #expect(snapshot.primaryPhotoData == data("first"))
    }
}

private extension NotificationRecipeSnapshotTests {
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
