@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Saving through a stale form must fail before it changes the graph.
@MainActor
struct DeletedMutationTargetTests: MutationRollbackTestSupport {
    @Test
    func rejects_same_context_update_of_deleted_recipe() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()
            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            var thrown: ReviewedMutationError?
            do {
                _ = try RecipeFormOperations.updateWithOutcome(
                    context: context,
                    recipe: recipe,
                    draft: try makeCurryDraft()
                )
                try context.save()
            } catch {
                thrown = error as? ReviewedMutationError
            }
            let reopened = try makeContext(at: url)
            let names = try reopened.fetch(.recipes(.all)).map(\.name)
            #expect(names.isEmpty)
            let ingredientObjects = try reopened.fetchCount(FetchDescriptor<IngredientObject>())
            #expect(ingredientObjects == 0)
            #expect(thrown == .targetMissing)
            #expect(context.hasChanges == false)
        }
    }

    @Test
    func rejects_cross_context_update_of_deleted_recipe() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            _ = makeRecipe(context: writer, name: "Curry")
            try writer.save()

            let editor = try makeContext(at: url)
            let stale = try #require(try editor.fetch(.recipes(.all)).first)
            _ = stale.name

            let deleter = try makeContext(at: url)
            let live = try #require(try deleter.fetch(.recipes(.all)).first)
            _ = RecipeOperations.deleteWithOutcome(context: deleter, recipe: live)
            try deleter.save()

            var thrown: ReviewedMutationError?
            do {
                _ = try RecipeFormOperations.updateWithOutcome(
                    context: editor,
                    recipe: stale,
                    draft: try makeCurryDraft()
                )
                try editor.save()
            } catch {
                thrown = error as? ReviewedMutationError
            }
            let reopened = try makeContext(at: url)
            let names = try reopened.fetch(.recipes(.all)).map(\.name)
            #expect(names.isEmpty)
            let ingredientObjects = try reopened.fetchCount(FetchDescriptor<IngredientObject>())
            #expect(ingredientObjects == 0)
            #expect(thrown == .targetMissing)
            #expect(editor.hasChanges == false)
        }
    }

    @Test
    func rejects_same_context_add_deleted_recipe_to_diary() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()
            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            var thrown: ReviewedMutationError?
            do {
                _ = try DiaryOperations.addWithOutcome(
                    context: context,
                    date: Self.day,
                    recipe: recipe,
                    type: .dinner
                )
                try context.save()
            } catch {
                thrown = error as? ReviewedMutationError
            }
            let reopened = try makeContext(at: url)
            let recipes = try reopened.fetch(.recipes(.all)).map(\.name)
            #expect(recipes.isEmpty)
            let diaries = try reopened.fetchCount(FetchDescriptor<Diary>())
            #expect(diaries == 0)
            let rows = try reopened.fetch(FetchDescriptor<DiaryObject>())
            #expect(rows.isEmpty)
            #expect(thrown == .targetMissing)
            #expect(context.hasChanges == false)
        }
    }

    @Test
    func rejects_same_context_create_diary_with_deleted_recipe() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Curry")
            try context.save()
            _ = RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
            try context.save()

            var thrown: ReviewedMutationError?
            do {
                _ = try DiaryOperations.createWithOutcome(
                    context: context,
                    input: .init(date: Self.day, dinners: [recipe], note: "Kept")
                )
                try context.save()
            } catch {
                thrown = error as? ReviewedMutationError
            }
            let reopened = try makeContext(at: url)
            let recipes = try reopened.fetch(.recipes(.all)).map(\.name)
            #expect(recipes.isEmpty)
            let notes = try reopened.fetch(FetchDescriptor<Diary>()).map(\.note)
            #expect(notes.isEmpty)
            let rows = try reopened.fetch(FetchDescriptor<DiaryObject>())
            #expect(rows.isEmpty)
            #expect(thrown == .targetMissing)
            #expect(context.hasChanges == false)
        }
    }

    @Test
    func rejects_same_context_update_of_deleted_diary() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let diary = Diary.create(
                context: context,
                content: .init(date: Self.day, objects: [], note: "Baked")
            )
            try context.save()
            _ = DiaryOperations.deleteWithOutcome(context: context, diary: diary)
            try context.save()

            var thrown: ReviewedMutationError?
            do {
                _ = try DiaryOperations.updateWithOutcome(
                    context: context,
                    diary: diary,
                    input: .init(date: Self.day, note: "Edited")
                )
                try context.save()
            } catch {
                thrown = error as? ReviewedMutationError
            }
            let reopened = try makeContext(at: url)
            let notes = try reopened.fetch(FetchDescriptor<Diary>()).map(\.note)
            #expect(notes.isEmpty)
            #expect(thrown == .targetMissing)
            #expect(context.hasChanges == false)
        }
    }
}
