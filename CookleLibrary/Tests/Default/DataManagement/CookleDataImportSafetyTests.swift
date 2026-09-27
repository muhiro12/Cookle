@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct CookleDataImportSafetyTests {
    typealias Store = CookleDataImportTestStore

    private struct SaveFailure: Error {}

    @Test
    func failed_replacement_reopens_with_original_photo_rows_and_recipe() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("store.sqlite")
        let container = try ModelContainerFactory.makeModelContainer(url: url, cloudKitDatabase: .none)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let target = Store(context: context)
        let current = try target.recipe("Curry", steps: ["Original"], photos: [Store.photo("original")])
        target.diary(day: 1, meals: [.init(recipe: current, type: .dinner)])
        try context.save()
        let source = Store()
        try source.recipe("Curry", steps: ["Backup"], photos: [Store.photo("backup")])
        let archive = try source.archive()
        let review = try target.review(of: archive)
        let conflict = try #require(review.recipeConflicts.first)
        #expect(throws: SaveFailure.self) {
            try CookleDataImportService.apply(
                archive,
                review: review,
                selections: .init(recipeChoices: [conflict.id: .useBackup(current.persistentModelID)]),
                context: context
            ) { _ in
                throw SaveFailure()
            }
        }
        let reopenedContainer = try ModelContainerFactory.makeModelContainer(url: url, cloudKitDatabase: .none)
        let reopened = Store(context: ModelContext(reopenedContainer))
        let recipe = try #require(try reopened.recipes(named: "Curry").first)
        #expect(recipe.steps == ["Original"])
        #expect(recipe.orderedPhotos.map(\.data) == [Data("original".utf8)])
        #expect(try reopened.count(Photo.self) == 1)
        #expect(try reopened.count(DiaryObject.self) == 1)
    }

    @Test
    func changed_backup_content_with_the_same_identifiers_requires_a_new_review() throws {
        let source = Store()
        try source.recipe("Curry", note: "Reviewed")
        let archive = try source.archive()
        let target = Store()
        let review = try target.review(of: archive)
        var wire = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(archive)) as? [String: Any])
        var recipes = try #require(wire["recipes"] as? [[String: Any]])
        recipes[0]["note"] = "Changed after review"
        wire["recipes"] = recipes
        let changed = try JSONDecoder().decode(
            CookleDataArchive.self,
            from: JSONSerialization.data(withJSONObject: wire)
        )
        #expect(throws: CookleDataImportError.self) {
            try DataMaintenanceOperations.importArchive(changed,
                                                        review: review,
                                                        selections: .init(),
                                                        context: target.context)
        }
        #expect(try target.count(Recipe.self) == .zero)
    }

    @Test
    func matching_photo_bytes_with_different_sources_preserve_both_sources() throws {
        let source = Store()
        try source.recipe("Backup", photos: [Store.photo("same", source: .imagePlayground)])
        let archive = try source.archive()
        let target = Store()
        let current = try target.recipe("Current", photos: [Store.photo("same")])
        try target.context.save()
        let originalSource = current.orderedPhotos.first?.sourceID
        let review = try target.review(of: archive)
        _ = try DataMaintenanceOperations.importArchive(archive,
                                                        review: review,
                                                        selections: .init(),
                                                        context: target.context)
        #expect(try target.count(Photo.self) == 2)
        #expect(current.orderedPhotos.first?.sourceID == originalSource)
        let importedSource = try target.recipes(named: "Backup").first?.orderedPhotos.first?.sourceID
        #expect(importedSource == PhotoSource.imagePlayground.rawValue)
    }

    @Test
    func repeating_combination_keeps_notes_and_repeated_meals_once() throws {
        let source = Store()
        let backup = try source.recipe("Toast")
        source.diary(day: 1, meals: [.init(recipe: backup, type: .breakfast)], note: "Backup note")
        let archive = try source.archive()
        let target = Store()
        let current = try target.recipe("Toast")
        let diary = target.diary(day: 1, meals: [.init(recipe: current, type: .breakfast)], note: "Current note")
        try target.context.save()
        for _ in 0..<2 {
            let review = try target.review(of: archive)
            let conflict = try #require(review.diaryConflicts.first)
            _ = try DataMaintenanceOperations.importArchive(
                archive,
                review: review,
                selections: .init(diaryChoices: [conflict.id: .combine]),
                context: target.context
            )
        }
        #expect(diary.note == "Current note\n\n---\n\nBackup note")
        #expect(diary.objects?.count == 1)
    }

    @Test
    func one_identical_candidate_among_multiple_matches_still_requires_a_choice() throws {
        let source = Store()
        try source.recipe("Curry", steps: ["Same"])
        let archive = try source.archive()
        let target = Store()
        try target.recipe("Curry", steps: ["Same"])
        try target.recipe("Curry", steps: ["Different"])
        try target.context.save()
        let review = try target.review(of: archive)
        #expect(review.recipeConflicts.count == 1)
        #expect(review.unchangedRecipeCount == .zero)
    }

    @Test
    func diary_meal_order_is_part_of_the_reviewed_content() throws {
        let source = Store()
        let first = try source.recipe("First")
        let second = try source.recipe("Second")
        source.diary(day: 1, meals: [.init(recipe: first, type: .lunch), .init(recipe: second, type: .lunch)])
        let archive = try source.archive()
        let target = Store()
        let currentFirst = try target.recipe("First")
        let currentSecond = try target.recipe("Second")
        target.diary(
            day: 1,
            meals: [.init(recipe: currentSecond, type: .lunch), .init(recipe: currentFirst, type: .lunch)]
        )
        try target.context.save()
        #expect(try target.review(of: archive).diaryConflicts.count == 1)
    }
}
