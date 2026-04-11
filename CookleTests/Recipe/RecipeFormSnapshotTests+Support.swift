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

    struct FlowModels {
        let create: RecipeFormModel
        let edit: RecipeFormModel
        let duplicate: RecipeFormModel
    }

    struct SnapshotKeys {
        let create: String
        let edit: String
        let duplicate: String
    }

    func makeSnapshotStore(
        userDefaults: UserDefaults = makeTestUserDefaults()
    ) -> FormSnapshotStore<RecipeFormSnapshot> {
        .init(
            userDefaults: userDefaults
        )
    }

    func makeCreateSnapshotKey() throws -> String {
        try #require(
            RecipeFormSnapshot.key(
                for: .create,
                recipe: nil
            )
        )
    }

    func makeLegacySnapshot() -> RecipeFormSnapshot {
        .init(
            name: "Legacy Recipe",
            servingSize: "2",
            cookingTime: "10",
            ingredients: [
                .init(
                    ingredient: "Bread",
                    amount: "2 slices"
                )
            ],
            steps: ["Toast"],
            categories: ["Breakfast"],
            note: "Legacy payload"
        )
    }

    func seedLegacySnapshot(
        _ snapshot: RecipeFormSnapshot,
        key: String,
        userDefaults: UserDefaults
    ) throws {
        let legacyValue = try #require(
            String(
                data: JSONEncoder().encode(snapshot),
                encoding: .utf8
            )
        )

        userDefaults.set(
            legacyValue,
            forKey: snapshotStorageKey(
                key
            )
        )
    }

    func makeFlowModels(
        snapshotStore: FormSnapshotStore<RecipeFormSnapshot>
    ) -> FlowModels {
        .init(
            create: RecipeFormModel(
                type: .create,
                snapshotStore: snapshotStore
            ),
            edit: RecipeFormModel(
                type: .edit,
                snapshotStore: snapshotStore
            ),
            duplicate: RecipeFormModel(
                type: .duplicate,
                snapshotStore: snapshotStore
            )
        )
    }

    func makeRecipeSnapshotKeys(
        recipe: Recipe
    ) throws -> SnapshotKeys {
        .init(
            create: try makeCreateSnapshotKey(),
            edit: try #require(
                RecipeFormSnapshot.key(
                    for: .edit,
                    recipe: recipe
                )
            ),
            duplicate: try #require(
                RecipeFormSnapshot.key(
                    for: .duplicate,
                    recipe: recipe
                )
            )
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

    func snapshotStorageKey(
        _ key: String
    ) -> String {
        CodablePreferenceNamespace.formSnapshot.preferenceKey(
            name: key,
            RecipeFormSnapshot.self
        ).storageKey
    }
}
