import CookleLibrary
import Foundation
import SwiftData
import Testing

@testable import Cookle

@MainActor
struct DiaryFormSnapshotTests {
    @Test
    func saveSnapshot_storesCodableData() {
        let userDefaults = makeTestUserDefaults()
        let snapshotStore: FormSnapshotStore<DiaryFormSnapshot> = .init(
            userDefaults: userDefaults
        )
        let snapshot = DiaryFormSnapshot(
            date: .now,
            breakfastRecipeIDs: [],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: [],
            note: "Stored as data"
        )

        snapshotStore.saveSnapshot(snapshot)

        let storedValue = userDefaults.object(
            forKey: snapshotStorageKey
        )
        #expect(storedValue is Data)
    }

    @Test
    func restoreSnapshot_roundTripsDateNoteAndMeals() throws {
        let context = try makeCookleTestContext()
        let breakfast = makeRecipe(
            context: context,
            name: "Toast"
        )
        let lunch = makeRecipe(
            context: context,
            name: "Soup"
        )
        let dinner = makeRecipe(
            context: context,
            name: "Curry"
        )
        let snapshotStore = makeSnapshotStore()
        let sourceModel = DiaryFormModel(
            snapshotStore: snapshotStore
        )
        let restoredModel = DiaryFormModel(
            snapshotStore: snapshotStore
        )
        let restoredDate = Date(
            timeIntervalSince1970: 1_234_567
        )

        sourceModel.applyInitialValues(
            diary: nil
        )
        sourceModel.activateSnapshotPersistence(
            diary: nil
        )
        sourceModel.date = restoredDate
        sourceModel.breakfasts = .init([breakfast])
        sourceModel.lunches = .init([lunch])
        sourceModel.dinners = .init([dinner])
        sourceModel.note = "Snapshot note"

        restoredModel.applyInitialValues(
            diary: nil
        )
        restoredModel.activateSnapshotPersistence(
            diary: nil
        )

        #expect(restoredModel.note.isEmpty)
        #expect(restoredModel.breakfasts.isEmpty)

        restoredModel.restoreSnapshot(
            context: context
        )

        #expect(restoredModel.date == restoredDate)
        #expect(restoredModel.breakfasts == Set([breakfast]))
        #expect(restoredModel.lunches == Set([lunch]))
        #expect(restoredModel.dinners == Set([dinner]))
        #expect(restoredModel.note == "Snapshot note")
    }

    @Test
    func restoreSnapshot_dropsUnresolvableRecipeIdentifiers() throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Toast"
        )
        let snapshotStore = makeSnapshotStore()
        let snapshot = DiaryFormSnapshot(
            date: .now,
            breakfastRecipeIDs: [
                RecipeStableIdentifierCodec.stableIdentifier(
                    for: recipe
                ),
                "invalid"
            ],
            lunchRecipeIDs: ["missing"],
            dinnerRecipeIDs: [],
            note: "Saved"
        )
        let model = DiaryFormModel(
            snapshotStore: snapshotStore
        )

        snapshotStore.saveSnapshot(snapshot)

        model.applyInitialValues(
            diary: nil
        )
        model.activateSnapshotPersistence(
            diary: nil
        )
        model.restoreSnapshot(
            context: context
        )

        #expect(model.breakfasts == Set([recipe]))
        #expect(model.lunches.isEmpty)
        #expect(model.dinners.isEmpty)
        #expect(model.note == "Saved")
    }

    @Test
    func save_clearsCurrentFlowSnapshot() async throws {
        let context = try makeCookleTestContext()
        let recipe = makeRecipe(
            context: context,
            name: "Salad"
        )
        let snapshotStore = makeSnapshotStore()
        let model = DiaryFormModel(
            snapshotStore: snapshotStore
        )

        model.applyInitialValues(
            diary: nil
        )
        model.activateSnapshotPersistence(
            diary: nil
        )
        model.breakfasts = .init([recipe])
        model.note = "Will save"

        #expect(snapshotStore.hasSnapshot())

        let didSave = await model.save(
            context: context,
            diary: nil,
            diaryActionService: DiaryActionService()
        )

        #expect(didSave)
        #expect(snapshotStore.hasSnapshot() == false)
    }

    @Test
    func editFlow_doesNotPersistSnapshot() throws {
        let context = try makeCookleTestContext()
        let diary = Diary.create(
            context: context,
            date: .now,
            objects: [],
            note: "Saved"
        )
        let snapshotStore = makeSnapshotStore()
        let model = DiaryFormModel(
            snapshotStore: snapshotStore
        )

        model.applyInitialValues(
            diary: diary
        )
        model.activateSnapshotPersistence(
            diary: diary
        )
        model.note = "Edited note"

        #expect(snapshotStore.hasSnapshot() == false)

        model.restoreSnapshot(
            context: context
        )

        #expect(model.note == "Edited note")
    }
}

private extension DiaryFormSnapshotTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTime = 5
    }

    var snapshotStorageKey: String {
        DiaryFormSnapshot.preferenceDescriptor.storageKey
    }

    func makeSnapshotStore() -> FormSnapshotStore<DiaryFormSnapshot> {
        .init(
            userDefaults: makeTestUserDefaults()
        )
    }

    func makeRecipe(
        context: ModelContext,
        name: String
    ) -> Recipe {
        Recipe.create(
            context: context,
            name: name,
            photos: [],
            servingSize: TestValues.servingSize,
            cookingTime: TestValues.cookingTime,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }
}
