@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins how a backup merges recipes into current data.
@MainActor
struct CookleDataImportRecipeTests {
    typealias Store = CookleDataImportTestStore

    @Test
    func an_empty_store_adds_every_record_with_photos_in_order_and_standalone_photos() throws {
        let source = Store()
        try source.recipe(
            "Curry",
            ingredients: [("Rice", "1 cup"), ("Egg", "2")],
            steps: ["Cook"],
            categories: ["Dinner"],
            photos: [Store.photo("second", source: .imagePlayground), Store.photo("first")]
        )
        _ = try Photo.create(context: source.context, photoData: Store.photo("standalone"))
        let archive = try source.archive()
        let target = Store()

        let review = try target.review(of: archive)
        #expect(review.hasConflicts == false)
        #expect(review.newRecipeCount == 1)

        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: target.context
        )

        #expect(summary.addedRecipeCount == 1)
        #expect(summary.addedPhotoCount == 3)
        let recipe = try #require(try target.recipes(named: "Curry").first)
        #expect(recipe.orderedPhotoObjects.compactMap(\.photo).map(\.data) == [Data("second".utf8), Data("first".utf8)])
        #expect(recipe.orderedPhotoObjects.first?.photo?.sourceID == PhotoSource.imagePlayground.rawValue)
        #expect((recipe.ingredientObjects ?? []).sorted().map(\.amount) == ["1 cup", "2"])
        #expect(try target.count(Photo.self) == 3)
    }

    @Test
    func repeating_an_import_changes_nothing_and_duplicates_nothing() throws {
        let store = Store()
        let curry = try store.recipe("Curry", ingredients: [("Rice", "1 cup")], photos: [Store.photo("curry")])
        store.diary(day: 1, meals: [.init(recipe: curry, type: .dinner)], note: "Good")
        let archive = try store.archive()

        let review = try store.review(of: archive)
        #expect(review.hasConflicts == false)
        #expect(review.unchangedRecipeCount == 1)
        #expect(review.unchangedDiaryCount == 1)

        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: store.context
        )

        #expect(summary.unchangedRecipeCount == 1)
        #expect(summary.addedPhotoCount == .zero)
        #expect(try store.count(Recipe.self) == 1)
        #expect(try store.count(Photo.self) == 1)
        #expect(try store.count(Ingredient.self) == 1)
        #expect(try store.count(DiaryObject.self) == 1)
    }

    @Test
    func a_differing_same_name_recipe_needs_a_choice_and_nothing_changes_without_one() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["Backup step"])
        let archive = try source.archive()
        let target = Store()
        try target.recipe(" curry ", steps: ["Current step"])
        try target.context.save()

        let review = try target.review(of: archive)
        let conflict = try #require(review.recipeConflicts.first)
        #expect(conflict.backup.steps == ["Backup step"])
        #expect(conflict.candidates.map(\.recipe.steps) == [["Current step"]])
        #expect(CookleDataImportSelections().isComplete(for: review) == false)

        #expect(throws: CookleDataImportError.invalidSelections) {
            try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: .init(),
                context: target.context
            )
        }
        #expect(target.context.hasChanges == false)
        #expect(try target.count(Recipe.self) == 1)
    }

    @Test
    func keeping_current_maps_backup_diaries_to_the_current_recipe() throws {
        let source = Store()
        let backupCurry = try source.recipe("Curry", steps: ["Backup step"])
        source.diary(day: 2, meals: [.init(recipe: backupCurry, type: .lunch)])
        let archive = try source.archive()
        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Current step"])
        try target.context.save()
        let review = try target.review(of: archive)
        let conflict = try #require(review.recipeConflicts.first)

        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(recipeChoices: [conflict.id: .keepCurrent(currentCurry.persistentModelID)]),
            context: target.context
        )

        #expect(try target.count(Recipe.self) == 1)
        #expect(currentCurry.steps == ["Current step"])
        #expect(currentCurry.diaryObjects?.count == 1)
    }

    @Test
    func using_the_backup_updates_the_chosen_recipe_in_place_for_its_diaries() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["Backup step"], photos: [Store.photo("backup")])
        let archive = try source.archive()
        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Current step"], photos: [Store.photo("current")])
        target.diary(day: 1, meals: [.init(recipe: currentCurry, type: .dinner)])
        try target.context.save()
        let identifier = currentCurry.persistentModelID
        let review = try target.review(of: archive)
        let conflict = try #require(review.recipeConflicts.first)
        #expect(conflict.candidates.first?.diaryMealRowCount == 1)

        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(recipeChoices: [conflict.id: .useBackup(identifier)]),
            context: target.context
        )

        #expect(summary.updatedRecipeCount == 1)
        let updated = try #require(try target.context.fetchFirst(.recipes(.idIs(identifier))))
        #expect(updated.steps == ["Backup step"])
        #expect(updated.orderedPhotos.map(\.data) == [Data("backup".utf8)])
        let diaryRecipe = try #require(try target.context.fetch(.diaries(.all)).first?.objects?.first?.recipe)
        #expect(diaryRecipe.persistentModelID == identifier)
        #expect(try target.count(Recipe.self) == 1)
    }

    @Test
    func keeping_both_adds_a_separate_recipe_for_backup_diaries() throws {
        let source = Store()
        let backupCurry = try source.recipe("Curry", steps: ["Backup step"])
        source.diary(day: 2, meals: [.init(recipe: backupCurry, type: .lunch)])
        let archive = try source.archive()
        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Current step"])
        try target.context.save()
        let review = try target.review(of: archive)
        let conflict = try #require(review.recipeConflicts.first)

        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(recipeChoices: [conflict.id: .keepBoth]),
            context: target.context
        )

        let curries = try target.recipes(named: "Curry")
        #expect(curries.count == 2)
        #expect(currentCurry.diaryObjects?.isEmpty ?? true)
        let added = try #require(curries.first { recipe in
            recipe.persistentModelID != currentCurry.persistentModelID
        })
        #expect(added.steps == ["Backup step"])
        #expect(added.diaryObjects?.count == 1)
    }

    @Test
    func identical_content_in_two_current_recipes_is_unchanged_and_needs_no_choice() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["Same"])
        let archive = try source.archive()
        let target = Store()
        try target.recipe("Curry", steps: ["Same"])
        try target.recipe("Curry", steps: ["Same"])
        try target.recipe("Salad")
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.hasConflicts == false)
        #expect(review.unchangedRecipeCount == 1)

        #expect(throws: CookleDataImportError.invalidSelections) {
            try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: .init(recipeChoices: ["extra": .keepBoth]),
                context: target.context
            )
        }
        let summary = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: target.context
        )
        #expect(summary.addedRecipeCount == .zero)
        #expect(try target.count(Recipe.self) == 3)
    }

    @Test
    func one_current_recipe_cannot_take_two_backup_versions() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["First"])
        try source.recipe("curry", steps: ["Second"])
        let archive = try source.archive()
        let target = Store()
        let current = try target.recipe("Curry", steps: ["Current"])
        try target.context.save()
        let review = try target.review(of: archive)
        #expect(review.recipeConflicts.count == 2)

        let choices = Dictionary(uniqueKeysWithValues: review.recipeConflicts.map { conflict in
            (conflict.id, CookleDataRecipeImportChoice.useBackup(current.persistentModelID))
        })
        #expect(throws: CookleDataImportError.invalidSelections) {
            try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: .init(recipeChoices: choices),
                context: target.context
            )
        }
    }
}
