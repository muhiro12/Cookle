@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Verifies what survives an upgrade from the 2.7 store shape.
///
/// `LegacySchemaMigrationTests` proves the upgrade *happens* and that
/// `Photo.sourceID` gains its default. These tests seed a populated store
/// instead — ordered ingredient rows with amounts, tags, a diary with meal rows,
/// several photos — and check the content after reopening with the current
/// schema, because an upgrade that loses ordering or relationships would still
/// look successful to a test that only reads one recipe name.
@MainActor
struct LegacyStoreUpgradeFidelityTests {
    @Test
    func upgraded_store_keeps_ordered_ingredient_rows_and_their_tags() throws {
        try withUpgradedStore { context in
            let recipe = try #require(try context.fetch(.recipes(.all)).first)
            let rows = (recipe.ingredientObjects ?? []).sorted { $0.order < $1.order }

            #expect(rows.map(\.order) == [1, 2, 3])
            #expect(rows.map { $0.ingredient?.value } == ["Flour", "Butter", "Sugar"])
            #expect(rows.map(\.amount) == ["200g", "80g", "50g"])

            // The flattened relation and the shared tag records must come across too.
            #expect(
                (recipe.ingredients ?? []).map(\.value).sorted() == ["Butter", "Flour", "Sugar"]
            )
            #expect(
                try context.fetch(.ingredients(.all)).map(\.value).sorted()
                    == ["Butter", "Flour", "Sugar"]
            )
        }
    }

    @Test
    func upgraded_store_keeps_categories_and_steps() throws {
        try withUpgradedStore { context in
            let recipe = try #require(try context.fetch(.recipes(.all)).first)

            #expect((recipe.categories ?? []).map(\.value) == ["Dessert"])
            #expect(recipe.steps == ["Cream the butter.", "Fold in the flour.", "Bake."])
            #expect(recipe.servingSize == 4)
            #expect(recipe.cookingTime == 45)
            #expect(recipe.note == "Rest the dough overnight.")
            #expect(try context.fetch(.categories(.all)).map(\.value) == ["Dessert"])
        }
    }

    @Test
    func upgraded_store_keeps_the_diary_date_and_its_ordered_meal_rows() throws {
        try withUpgradedStore { context in
            let diary = try #require(try context.fetch(.diaries(.all)).first)
            let rows = (diary.objects ?? []).sorted { $0.order < $1.order }

            #expect(diary.date == Self.diaryDate)
            #expect(diary.note == "Baked for guests.")
            #expect(rows.map(\.order) == [1, 2])
            #expect(rows.map(\.type) == [.lunch, .dinner])
            #expect(rows.allSatisfy { $0.recipe?.name == "Shortbread" })
            #expect((diary.recipes ?? []).map(\.name) == ["Shortbread"])
        }
    }

    @Test
    func upgraded_store_keeps_photo_bytes_and_their_display_order() throws {
        try withUpgradedStore { context in
            let recipe = try #require(try context.fetch(.recipes(.all)).first)
            let rows = (recipe.photoObjects ?? []).sorted { $0.order < $1.order }

            #expect(rows.map(\.order) == [1, 2])
            #expect(rows.map { $0.photo?.data } == [Self.firstPhoto, Self.secondPhoto])
            // 2.7 had no `sourceID`; every upgraded asset takes the default.
            #expect(
                rows.allSatisfy { $0.photo?.sourceID == PhotoSource.defaultValue.rawValue }
            )
        }
    }

    @Test
    func an_upgraded_store_can_still_be_exported_as_an_archive() throws {
        try withUpgradedStore { context in
            // Backups have to work on a store that arrived by upgrade, not only
            // on one this version created.
            let archive = try CookleDataArchiveService.makeArchive(context: context)

            #expect(archive.recipes.count == 1)
            #expect(archive.diaries.count == 1)
            #expect(archive.photos.count == 2)
            #expect(archive.ingredients.map(\.value).sorted() == ["Butter", "Flour", "Sugar"])
            #expect(archive.categories.map(\.value) == ["Dessert"])

            let recipeRecord = try #require(archive.recipes.first)
            #expect(recipeRecord.ingredients.map(\.order) == [1, 2, 3])
            #expect(recipeRecord.photos.map(\.order) == [1, 2])
        }
    }
}

private extension LegacyStoreUpgradeFidelityTests {
    static let firstPhoto = Data([1, 1, 1])
    static let secondPhoto = Data([2, 2, 2])
    static let diaryDate = Date(timeIntervalSince1970: 1_700_000_000)

    /// Seeds a 2.7-shaped store, reopens it with the current schema, and hands
    /// the upgraded context to the caller.
    func withUpgradedStore(_ body: (ModelContext) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("default.store")
        try seedLegacyStore(at: url)

        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        try body(context)
    }

    func seedLegacyStore(at url: URL) throws {
        let container = try ModelContainer(
            for: Schema(ReleasedSchemaV0.models),
            configurations: .init(url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)

        let recipe = ReleasedSchemaV0.Recipe()
        context.insert(recipe)
        recipe.name = "Shortbread"
        recipe.servingSize = 4
        recipe.cookingTime = 45
        recipe.note = "Rest the dough overnight."
        recipe.steps = ["Cream the butter.", "Fold in the flour.", "Bake."]

        let ingredientRows = [
            ("Flour", "200g", 1),
            ("Butter", "80g", 2),
            ("Sugar", "50g", 3)
        ]
        .map { value, amount, order in
            let ingredient = ReleasedSchemaV0.Ingredient()
            ingredient.value = value
            let row = ReleasedSchemaV0.IngredientObject()
            row.ingredient = ingredient
            row.amount = amount
            row.order = order
            return (ingredient, row)
        }
        recipe.ingredients = ingredientRows.map(\.0)
        recipe.ingredientObjects = ingredientRows.map(\.1)

        let category = ReleasedSchemaV0.Category()
        category.value = "Dessert"
        recipe.categories = [category]

        let photoRows = [
            (Self.firstPhoto, 1),
            (Self.secondPhoto, 2)
        ]
        .map { data, order in
            let photo = ReleasedSchemaV0.Photo()
            photo.data = data
            let row = ReleasedSchemaV0.PhotoObject()
            row.photo = photo
            row.order = order
            return (photo, row)
        }
        recipe.photos = photoRows.map(\.0)
        recipe.photoObjects = photoRows.map(\.1)

        let diary = ReleasedSchemaV0.Diary()
        context.insert(diary)
        diary.date = Self.diaryDate
        diary.note = "Baked for guests."
        diary.recipes = [recipe]
        diary.objects = [DiaryObjectType.lunch, DiaryObjectType.dinner]
            .enumerated()
            .map { offset, type in
                let row = ReleasedSchemaV0.DiaryObject()
                row.recipe = recipe
                row.type = type
                row.order = offset + 1
                return row
            }

        try context.save()
    }
}
