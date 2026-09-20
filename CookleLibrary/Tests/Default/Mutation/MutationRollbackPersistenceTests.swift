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

    // Disabled because it does not fail — it traps. SwiftData raises
    // `Fatal error: Unexpected backing data for snapshot creation:
    // _FullFutureBackingData<DiaryObject>` inside `rollback()`, which aborts the
    // whole test process. Kept as the reproduction for #129; re-enable with the fix.
    @Test(.disabled("Traps inside SwiftData rollback; reproduction for #129"))
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
                    date: Self.day.addingTimeInterval(60),
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
}

private extension MutationRollbackPersistenceTests {
    static let day = Date(timeIntervalSinceReferenceDate: 800_000_000)

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

    func makeRecipe(context: ModelContext, name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: 1,
                cookingTime: 10,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
    }
}
