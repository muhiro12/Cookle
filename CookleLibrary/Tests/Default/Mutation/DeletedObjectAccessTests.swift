@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// A detail screen keeps its model after another path deletes the record, and
// its edit and delete controls stay live. Cookle relies on the platform's own
// behaviour there rather than dismissing or tombstoning the screen, so these
// tests record what that behaviour actually is.
//
// The headline is in `isDeleted_is_false_for_a_deleted_and_saved_model`: the
// obvious liveness check does not work, and reading an unresolved attribute of
// such a model is a `fatalError` inside SwiftData, not a recoverable error.
// Re-fetching by `persistentModelID` is the check that does work.
@MainActor
struct DeletedObjectAccessTests {
    @Test
    func isDeleted_is_false_for_a_deleted_and_saved_model() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()

            context.delete(recipe)

            // Before the save it reports correctly.
            #expect(recipe.isDeleted)

            try context.save()

            // After the save the model is detached and `isDeleted` reverts to
            // false, so a view holding it cannot use this to tell it is gone.
            //
            // Reading an attribute that was never faulted in — `steps` on this
            // model — traps here with "This backing data was detached from a
            // context without resolving attribute faults". That is a process
            // kill, so it is deliberately not exercised.
            #expect(recipe.isDeleted == false)
        }
    }

    @Test
    func refetching_by_identifier_is_the_check_that_works() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()
            let identifier = recipe.persistentModelID

            #expect(try context.fetch(.recipes(.idIs(identifier))).isEmpty == false)

            context.delete(recipe)
            try context.save()

            #expect(try context.fetch(.recipes(.idIs(identifier))).isEmpty)
        }
    }

    @Test
    func deleting_an_already_deleted_recipe_is_a_no_op() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()

            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            // What the still-live delete button on a stale screen does.
            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).isEmpty)
        }
    }

    @Test
    func deleting_an_already_deleted_diary_is_a_no_op() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let diary = Diary.create(
                context: context,
                content: .init(date: Self.day, objects: [], note: "Baked")
            )
            try context.save()

            _ = DiaryOperations.deleteWithOutcome(context: context, diary: diary)
            try context.save()
            _ = DiaryOperations.deleteWithOutcome(context: context, diary: diary)
            try context.save()

            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.diaries(.all)).isEmpty)
        }
    }
}

private extension DeletedObjectAccessTests {
    enum Value {
        static let servingSize = 1
        static let cookingTimeMinutes = 10
        static let dayReference: TimeInterval = 800_000_000
    }

    static var day: Date {
        Date(timeIntervalSinceReferenceDate: Value.dayReference)
    }

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
        context.autosaveEnabled = false
        return context
    }

    func makeRecipe(context: ModelContext, name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: Value.servingSize,
                cookingTime: Value.cookingTimeMinutes,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }
}
