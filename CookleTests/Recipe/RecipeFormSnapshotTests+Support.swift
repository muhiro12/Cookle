import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

extension RecipeFormSnapshotTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTime = 5
    }

    var snapshotStorageKey: String {
        RecipeFormSnapshot.preferenceDescriptor.storageKey
    }

    func makeSnapshotStore(
        userDefaults: UserDefaults = makeTestUserDefaults()
    ) -> FormSnapshotStore<RecipeFormSnapshot> {
        .init(
            userDefaults: userDefaults
        )
    }

    func makeRecipe(
        context: ModelContext,
        name: String = "Base Recipe",
        note: String = "Original"
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: name,
            photos: [],
            servingSize: TestValues.servingSize,
            cookingTime: TestValues.cookingTime,
            ingredients: [],
            steps: ["Toast bread"],
            categories: [],
            note: note
        )
    }

    func populateCreateDraft(
        _ model: RecipeFormModel
    ) {
        model.name = "French Toast"
        model.photos = [samplePhotoData()]
        model.servingSize = "2"
        model.cookingTime = "10"
        model.ingredients = [
            .init(
                ingredient: "Bread",
                amount: "2 slices"
            ),
            .init(
                ingredient: "",
                amount: ""
            )
        ]
        model.steps = ["Whisk eggs", ""]
        model.categories = ["Breakfast", ""]
        model.note = "Best served warm"
    }

    func populateSavableDraft(
        _ model: RecipeFormModel
    ) {
        model.name = "Saved Recipe"
        model.servingSize = "2"
        model.cookingTime = "15"
        model.ingredients = [
            .init(
                ingredient: "Flour",
                amount: "100g"
            ),
            .init(
                ingredient: "",
                amount: ""
            )
        ]
        model.steps = ["Bake", ""]
        model.categories = ["Dessert", ""]
        model.note = "Snapshot should clear"
        model.photos = [samplePhotoData()]
    }

    func samplePhotoData() -> PhotoData {
        .init(
            data: Data("photo".utf8),
            source: .photosPicker
        )
    }
}
