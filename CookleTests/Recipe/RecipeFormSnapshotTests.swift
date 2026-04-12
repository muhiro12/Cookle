import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct RecipeFormSnapshotTests {
    @Test
    func saveSnapshot_storesCodableData() {
        let userDefaults = makeTestUserDefaults()
        let snapshotStore: FormSnapshotStore<RecipeFormSnapshot> = .init(
            userDefaults: userDefaults
        )
        let snapshot = RecipeFormSnapshot(
            name: "Data payload",
            servingSize: "2",
            cookingTime: "5",
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )

        snapshotStore.saveSnapshot(snapshot)

        let storedValue = userDefaults.object(
            forKey: snapshotStorageKey
        )
        #expect(storedValue is Data)
    }

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
        let createModel = RecipeFormModel(
            type: .create,
            snapshotStore: snapshotStore
        )
        createModel.activateSnapshotPersistence(
            recipe: nil
        )
        createModel.name = "Saved Draft"
        createModel.note = "Saved note"

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

        #expect(model.name == "Base Recipe")
        #expect(model.note == "Original")
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

        model.activateSnapshotPersistence(
            recipe: nil
        )
        populateSavableDraft(
            model
        )

        #expect(snapshotStore.hasSnapshot())

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
        #expect(snapshotStore.hasSnapshot() == false)
    }

    @Test
    func duplicateFlow_doesNotPersistSnapshot() throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Pancakes",
            note: ""
        )
        try context.save()
        let snapshotStore = makeSnapshotStore()
        let model = RecipeFormModel(
            type: .duplicate,
            snapshotStore: snapshotStore
        )

        model.applyRecipeIfNeeded(
            recipe
        )
        model.activateSnapshotPersistence(
            recipe: recipe
        )
        model.name = "Duplicate Draft"
        model.note = "Should not persist"

        #expect(snapshotStore.hasSnapshot() == false)

        model.restoreSnapshot()

        #expect(model.name == "Duplicate Draft")
        #expect(model.note == "Should not persist")
    }
}
