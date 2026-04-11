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
        let snapshotKey = DiaryFormSnapshot.key(
            for: nil
        )
        let snapshot = DiaryFormSnapshot(
            date: .now,
            breakfastRecipeIDs: [],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: [],
            note: "Stored as data"
        )

        snapshotStore.saveSnapshot(
            snapshot,
            for: snapshotKey
        )

        let storedValue = userDefaults.object(
            forKey: snapshotStorageKey(
                snapshotKey
            )
        )
        #expect(storedValue is Data)
    }

    @Test
    func restoreSnapshot_migratesLegacyStringPayloadToData() throws {
        let context = try makeCookleTestContext()
        let userDefaults = makeTestUserDefaults()
        let snapshotStore: FormSnapshotStore<DiaryFormSnapshot> = .init(
            userDefaults: userDefaults
        )
        let snapshotKey = DiaryFormSnapshot.key(
            for: nil
        )
        let snapshot = DiaryFormSnapshot(
            date: .now,
            breakfastRecipeIDs: [],
            lunchRecipeIDs: [],
            dinnerRecipeIDs: [],
            note: "Legacy payload"
        )
        let model = DiaryFormModel(
            snapshotStore: snapshotStore
        )
        let legacyValue = try #require(
            String(
                data: JSONEncoder().encode(snapshot),
                encoding: .utf8
            )
        )

        userDefaults.set(
            legacyValue,
            forKey: snapshotStorageKey(
                snapshotKey
            )
        )

        model.applyInitialValues(
            diary: nil
        )
        model.activateSnapshotPersistence(
            diary: nil
        )
        model.restoreSnapshot(
            context: context
        )

        #expect(model.note == "Legacy payload")
        let storedValue = userDefaults.object(
            forKey: snapshotStorageKey(
                snapshotKey
            )
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
        let snapshotKey = DiaryFormSnapshot.key(
            for: nil
        )
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

        snapshotStore.saveSnapshot(
            snapshot,
            for: snapshotKey
        )

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
        let snapshotKey = DiaryFormSnapshot.key(
            for: nil
        )
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

        #expect(snapshotStore.hasSnapshot(for: snapshotKey))

        let didSave = await model.save(
            context: context,
            diary: nil,
            diaryActionService: DiaryActionService()
        )

        #expect(didSave)
        #expect(snapshotStore.hasSnapshot(for: snapshotKey) == false)
    }
}

private extension DiaryFormSnapshotTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTime = 5
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

    func snapshotStorageKey(
        _ key: String
    ) -> String {
        CodablePreferenceNamespace.formSnapshot.preferenceKey(
            name: key,
            DiaryFormSnapshot.self
        ).storageKey
    }
}
