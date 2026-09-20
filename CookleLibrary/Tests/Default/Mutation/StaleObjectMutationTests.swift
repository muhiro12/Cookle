@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Records what happens when a mutation runs against a record another context
/// has already changed or deleted.
///
/// Cookle reviews destructive mutations before applying them: the tag and recipe
/// delete dialogs quote how many related records will be touched. That count is
/// read when the dialog is built, so these tests pin whether the value still
/// holds when the mutation finally runs.
@MainActor
struct StaleObjectMutationTests {
    @Test
    func deleting_a_recipe_another_context_already_deleted_leaves_the_store_consistent() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            _ = makeRecipe(context: writer, name: "Curry")
            try writer.save()

            let reader = try makeContext(at: url)
            let stale = try #require(try reader.fetch(.recipes(.all)).first)

            // Another context removes the record while `stale` is still held.
            let deleter = try makeContext(at: url)
            let live = try #require(try deleter.fetch(.recipes(.all)).first)
            _ = RecipeOperations.deleteWithOutcome(context: deleter, recipe: live)
            try deleter.save()

            _ = RecipeOperations.deleteWithOutcome(context: reader, recipe: stale)
            try reader.save()

            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).isEmpty)
            #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == .zero)
        }
    }

    @Test
    func a_reviewed_category_impact_count_can_be_stale_when_the_mutation_runs() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            let category = try Category.create(context: writer, value: "Dinner")
            let firstRecipe = makeRecipe(context: writer, name: "Curry")
            firstRecipe.updateCategories([category])
            try writer.save()

            // What the delete dialog quotes when it is built.
            let reviewer = try makeContext(at: url)
            let reviewed = try #require(try reviewer.fetch(.categories(.all)).first)
            let reviewedCount = (reviewed.recipes ?? []).count
            #expect(reviewedCount == 1)

            // Another context attaches a second recipe before the user confirms.
            let other = try makeContext(at: url)
            let otherCategory = try #require(try other.fetch(.categories(.all)).first)
            let secondRecipe = makeRecipe(context: other, name: "Salad")
            secondRecipe.updateCategories([otherCategory])
            try other.save()

            let verifier = try makeContext(at: url)
            let stored = try #require(try verifier.fetch(.categories(.all)).first)
            #expect((stored.recipes ?? []).count == 2)

            // The instance the review was built from, read without re-fetching.
            let heldCount = (reviewed.recipes ?? []).count
            #expect(heldCount == 1)

            // What re-resolving the record in the same context reports.
            let refetched = try #require(try reviewer.fetch(.categories(.all)).first)
            #expect((refetched.recipes ?? []).count == 2)
        }
    }
}

private extension StaleObjectMutationTests {
    enum TestValues {
        static let servingSize = 1
        static let cookingTimeMinutes = 10
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
