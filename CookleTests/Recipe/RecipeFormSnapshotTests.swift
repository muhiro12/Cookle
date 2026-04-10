import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct RecipeFormSnapshotTests {
    @Test
    func restoreSnapshot_roundTripsRawInputWithoutPhotos() {
        let snapshotStore = makeSnapshotStore()
        let sourceModel = RecipeFormModel(
            type: .create,
            snapshotStore: snapshotStore
        )
        let restoredModel = RecipeFormModel(
            type: .create,
            snapshotStore: snapshotStore
        )

        sourceModel.activateSnapshotPersistence(
            recipe: nil
        )
        populateCreateDraft(
            sourceModel
        )
        restoredModel.activateSnapshotPersistence(
            recipe: nil
        )
        #expect(restoredModel.name.isEmpty)
        #expect(restoredModel.photos.isEmpty)

        restoredModel.restoreSnapshot()

        #expect(restoredModel.name == "French Toast")
        #expect(restoredModel.photos.isEmpty)
        #expect(restoredModel.servingSize == "2")
        #expect(restoredModel.cookingTime == "10")
        #expect(restoredModel.ingredients.first?.ingredient == "Bread")
        #expect(restoredModel.steps == ["Whisk eggs", ""])
        #expect(restoredModel.categories == ["Breakfast", ""])
        #expect(restoredModel.note == "Best served warm")
    }

    @Test
    func restoreSnapshot_doesNotAutoApplyOverEditBaseState() throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context
        )
        try context.save()
        let snapshotStore = makeSnapshotStore()
        let snapshotKey = try #require(
            RecipeFormSnapshot.key(
                for: .edit,
                recipe: recipe
            )
        )

        snapshotStore.saveSnapshot(
            .init(
                name: "Saved Draft",
                servingSize: "3",
                cookingTime: "15",
                ingredients: [
                    .init(
                        ingredient: "Eggs",
                        amount: "2"
                    )
                ],
                steps: ["Saved step"],
                categories: ["Brunch"],
                note: "Saved note"
            ),
            for: snapshotKey
        )

        let model = RecipeFormModel(
            type: .edit,
            snapshotStore: snapshotStore
        )

        model.applyRecipeIfNeeded(
            recipe
        )
        model.activateSnapshotPersistence(
            recipe: recipe
        )

        #expect(model.name == "Base Recipe")
        #expect(model.note == "Original")

        model.restoreSnapshot()

        #expect(model.name == "Saved Draft")
        #expect(model.note == "Saved note")
        #expect(model.steps == ["Saved step", ""])
    }

    @Test
    func save_clearsCurrentFlowSnapshot() async throws {
        let modelContainer = try makeCookleTestContainer()
        let context = modelContainer.mainContext
        let assembly = CookleAppAssemblyFactory.preview(
            modelContainer: modelContainer
        )
        let snapshotStore = makeSnapshotStore()
        let model = RecipeFormModel(
            type: .create,
            snapshotStore: snapshotStore
        )
        let snapshotKey = try #require(
            RecipeFormSnapshot.key(
                for: .create,
                recipe: nil
            )
        )

        model.activateSnapshotPersistence(
            recipe: nil
        )
        populateSavableDraft(
            model
        )

        #expect(snapshotStore.hasSnapshot(for: snapshotKey))

        let didSave = await model.save(
            context: context,
            recipe: nil,
            recipeActionService: assembly.recipeActionService,
            draftLogger: CookleAppLogging.preview().logger(
                category: "RecipeFormSnapshotTests",
                source: #fileID
            )
        )

        #expect(didSave)
        #expect(snapshotStore.hasSnapshot(for: snapshotKey) == false)
    }

    @Test
    func snapshotKeys_doNotMixCreateEditAndDuplicate() throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Pancakes",
            note: ""
        )
        try context.save()
        let snapshotStore = makeSnapshotStore()
        let flowModels = makeFlowModels(
            snapshotStore: snapshotStore
        )
        let snapshotKeys = try makeRecipeSnapshotKeys(
            recipe: recipe
        )

        flowModels.create.activateSnapshotPersistence(
            recipe: nil
        )
        flowModels.create.name = "Create Draft"

        flowModels.edit.applyRecipeIfNeeded(
            recipe
        )
        flowModels.edit.activateSnapshotPersistence(
            recipe: recipe
        )
        flowModels.edit.name = "Edit Draft"

        flowModels.duplicate.applyRecipeIfNeeded(
            recipe
        )
        flowModels.duplicate.activateSnapshotPersistence(
            recipe: recipe
        )
        flowModels.duplicate.name = "Duplicate Draft"

        #expect(snapshotStore.snapshot(for: snapshotKeys.create)?.name == "Create Draft")
        #expect(snapshotStore.snapshot(for: snapshotKeys.edit)?.name == "Edit Draft")
        #expect(snapshotStore.snapshot(for: snapshotKeys.duplicate)?.name == "Duplicate Draft")
    }
}

private extension RecipeFormSnapshotTests {
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

    func makeSnapshotStore() -> FormSnapshotStore<RecipeFormSnapshot> {
        .init(
            userDefaults: makeTestUserDefaults()
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
            create: try #require(
                RecipeFormSnapshot.key(
                    for: .create,
                    recipe: nil
                )
            ),
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
}
