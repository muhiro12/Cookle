@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Verifies the all-or-nothing contract `CookleMutationWorkflow` relies on:
/// when a mutation fails, `rollback()` must leave the store on disk untouched.
///
/// The workflow itself lives in the app target, so these tests reproduce its
/// shape — run an Operation, roll the context back instead of saving, then
/// reopen the store from disk and compare the persisted graph.
@MainActor
struct MutationRollbackPersistenceTests {
    @Test
    func rolled_back_diary_update_leaves_the_reopened_store_unchanged() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            let diary = try DiaryOperations.createWithOutcome(
                context: context,
                input: .init(date: Self.day, dinners: [recipe], note: "Original note")
            )
            .value
            try context.save()

            let secondRecipe = makeRecipe(context: context, name: "Salad")
            _ = try DiaryOperations.updateWithOutcome(
                context: context,
                diary: diary,
                input: .init(date: Self.day, lunches: [secondRecipe], note: "Replaced note")
            )
            context.rollback()

            let reopened = try makeContext(at: url)
            let diaries = try reopened.fetch(.diaries(.all))
            #expect(diaries.count == 1)
            #expect(diaries.first?.note == "Original note")
            #expect(diaries.first?.recipes?.map(\.name) == ["Curry"])
            // The relationship edit is discarded along with the recipe it created.
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Curry"])
        }
    }

    // Before `CascadeDeletionSupport`, this did not fail — it trapped inside
    // `rollback()` and aborted the whole test process.
    @Test
    func rolled_back_diary_deletion_leaves_the_reopened_store_unchanged() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            let diary = try DiaryOperations.createWithOutcome(
                context: context,
                input: .init(date: Self.day, dinners: [recipe], note: "Keep me")
            )
            .value
            try context.save()

            _ = DiaryOperations.deleteWithOutcome(context: context, diary: diary)
            context.rollback()

            let reopened = try makeContext(at: url)
            let diaries = try reopened.fetch(.diaries(.all))
            #expect(diaries.count == 1)
            #expect(diaries.first?.note == "Keep me")
            #expect(diaries.first?.recipes?.map(\.name) == ["Curry"])
        }
    }

    @Test
    func rolled_back_duplicate_day_repair_leaves_both_diaries_on_disk() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try DiaryOperations.createWithOutcome(
                context: context,
                input: .init(date: Self.day, note: "First")
            )
            // Operations reject a second diary on an occupied day, so the
            // duplicate is inserted directly — the shape a sync merge produces.
            _ = Diary.create(
                context: context,
                content: .init(
                    date: Self.day.addingTimeInterval(TestValues.duplicateDayOffset),
                    objects: [],
                    note: "Second"
                )
            )
            try context.save()

            let report = try DiaryOperations.duplicateDayReport(context: context)
            #expect(report.hasConflicts)

            _ = try DiaryOperations.repairDuplicateDaysWithOutcome(context: context)
            context.rollback()

            let reopened = try makeContext(at: url)
            let notes = try reopened.fetch(.diaries(.all)).map(\.note).sorted()
            // Repair merges the day; rolling it back must not half-merge the store.
            #expect(notes == ["First", "Second"])
        }
    }

    @Test
    func rolled_back_recipe_deletion_leaves_the_reopened_store_unchanged() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            _ = try DiaryOperations.createWithOutcome(
                context: context,
                input: .init(date: Self.day, dinners: [recipe], note: "Cooked it")
            )
            try context.save()

            let reloaded = try makeContext(at: url)
            let stored = try #require(try reloaded.fetch(.recipes(.all)).first)
            _ = RecipeOperations.deleteWithOutcome(context: reloaded, recipe: stored)
            reloaded.rollback()

            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Curry"])
            #expect(try reopened.fetch(.diaries(.all)).first?.recipes?.count == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<DiaryObject>()) == 1)
        }
    }

    @Test
    func rolled_back_photo_deletion_leaves_the_reopened_store_unchanged() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            try seedPhotographedRecipe(context: context)
            try context.save()

            let reloaded = try makeContext(at: url)
            let stored = try #require(try reloaded.fetch(FetchDescriptor<Photo>()).first)
            _ = PhotoOperations.deleteWithOutcome(context: reloaded, photo: stored)
            reloaded.rollback()

            let reopened = try makeContext(at: url)
            #expect(try reopened.fetchCount(FetchDescriptor<Photo>()) == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<PhotoObject>()) == 1)
        }
    }

    @Test
    func rolled_back_recipe_creation_leaves_no_partial_records() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let draft = try RecipeFormOperations.makeDraft(
                input: .init(
                    name: "Curry",
                    photos: [],
                    servingSize: "2",
                    cookingTime: "30",
                    ingredients: [
                        .init(ingredient: "Onion", amount: "1"),
                        .init(ingredient: "Rice", amount: "2 cups")
                    ],
                    steps: ["Chop.", "Simmer."],
                    categories: ["Dinner"],
                    note: "Weeknight"
                )
            )
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: draft
            )
            context.rollback()

            // Creating a recipe also creates Ingredient and Category records as a
            // side effect. An abandoned save must not leave those behind to
            // pollute the user's tag lists.
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).isEmpty)
            #expect(try reopened.fetch(.ingredients(.all)).isEmpty)
            #expect(try reopened.fetch(.categories(.all)).isEmpty)
            #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == .zero)
        }
    }
}

private extension MutationRollbackPersistenceTests {
    enum TestValues {
        static let dayReference: TimeInterval = 800_000_000
        static let duplicateDayOffset: TimeInterval = 60
        static let servingSize = 1
        static let cookingTimeMinutes = 10
    }

    static let day = Date(timeIntervalSinceReferenceDate: TestValues.dayReference)

    func withDiskStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory.appendingPathComponent("store.sqlite"))
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        // Autosave would defeat the point: rollback can only prove anything
        // while the mutation is still uncommitted.
        context.autosaveEnabled = false
        return context
    }

    func seedPhotographedRecipe(context: ModelContext) throws {
        let photo = try Photo.create(
            context: context,
            photoData: .init(data: Data("photo".utf8), source: .photosPicker)
        )
        let photoObject = PhotoObject.restore(
            context: context,
            photo: photo,
            order: .zero,
            createdTimestamp: .now,
            modifiedTimestamp: .now
        )
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Curry",
                photos: [photoObject],
                servingSize: TestValues.servingSize,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }

    func makeRecipe(context: ModelContext, name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: TestValues.servingSize,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }
}
