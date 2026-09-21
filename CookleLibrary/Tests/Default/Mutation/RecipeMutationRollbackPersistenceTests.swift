@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Rollback persistence for recipe content, ordered rows, and photo assets.
///
/// Same contract as `MutationRollbackPersistenceTests`: run an Operation, roll
/// the context back instead of saving, reopen the store and compare. These
/// cases exercise the edits that touch more than one field or relationship,
/// where an incomplete undo is easiest to miss.
@MainActor
struct RecipeMutationRollbackPersistenceTests: MutationRollbackTestSupport {
    @Test
    func rolled_back_relationship_edit_leaves_the_original_rows_on_disk() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: try makeCurryDraft()
            )
            try context.save()

            // An edit replaces every ingredient row and re-points the category
            // relation, so a failed save has to undo more than one field.
            let editing = try makeContext(at: url)
            let recipe = try #require(try editing.fetch(.recipes(.all)).first)
            _ = try RecipeFormOperations.updateWithOutcome(
                context: editing,
                recipe: recipe,
                draft: try makeReplacementCurryDraft()
            )
            editing.rollback()

            let reopened = try makeContext(at: url)
            let stored = try #require(try reopened.fetch(.recipes(.all)).first)
            let rows = (stored.ingredientObjects ?? [])
                .sorted { $0.order < $1.order }

            #expect(rows.map { $0.ingredient?.value } == ["Onion", "Rice"])
            #expect(rows.map(\.amount) == ["1", "2 cups"])
            #expect(rows.map(\.order) == [1, 2])
            #expect((stored.categories ?? []).map(\.value) == ["Dinner"])
            // The replacement rows and the tag the edit would have introduced
            // must not survive the abandoned save either.
            #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == 2)
            #expect(
                try reopened.fetch(.ingredients(.all)).map(\.value).sorted() == ["Onion", "Rice"]
            )
            #expect(try reopened.fetch(.categories(.all)).map(\.value) == ["Dinner"])
        }
    }

    // `Photo.create` used to rewrite `data` and `sourceID` even when it had just
    // found the row by an exact `data` match. That marked the reused asset dirty
    // while its cascade-owned `PhotoObject` was being deleted in the same turn,
    // and `rollback()` then trapped inside SwiftData and took the process down —
    // so this did not fail, it aborted the run.
    @Test
    func rolled_back_edit_of_a_photographed_recipe_keeps_the_asset() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: try makePhotoDraft(photoNames: ["only"])
            )
            try context.save()

            // The plainest edit there is: same photo, different name.
            let editing = try makeContext(at: url)
            let recipe = try #require(try editing.fetch(.recipes(.all)).first)
            _ = try RecipeFormOperations.updateWithOutcome(
                context: editing,
                recipe: recipe,
                draft: try makePhotoDraft(
                    photoNames: ["only"],
                    name: "Renamed"
                )
            )
            editing.rollback()

            let reopened = try makeContext(at: url)
            let stored = try #require(try reopened.fetch(.recipes(.all)).first)
            #expect(stored.name == "Curry")
            #expect(try reopened.fetchCount(FetchDescriptor<Photo>()) == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<PhotoObject>()) == 1)
        }
    }

    @Test
    func rolled_back_photo_reorder_leaves_the_original_order_on_disk() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: try makePhotoDraft(
                    photoNames: ["first", "second", "third"]
                )
            )
            try context.save()

            let editing = try makeContext(at: url)
            let recipe = try #require(try editing.fetch(.recipes(.all)).first)
            _ = try RecipeFormOperations.updateWithOutcome(
                context: editing,
                recipe: recipe,
                draft: try makePhotoDraft(
                    photoNames: ["third", "first", "second"]
                )
            )
            editing.rollback()

            let reopened = try makeContext(at: url)
            let stored = try #require(try reopened.fetch(.recipes(.all)).first)
            let rows = (stored.photoObjects ?? [])
                .sorted { $0.order < $1.order }

            #expect(rows.map(\.order) == [1, 2, 3])
            #expect(
                rows.map { $0.photo.flatMap { photo in String(data: photo.data, encoding: .utf8) } }
                    == ["first", "second", "third"]
            )
            // Reordering reuses the same three assets, so an abandoned save must
            // leave three rows and three assets, not six.
            #expect(try reopened.fetchCount(FetchDescriptor<PhotoObject>()) == 3)
            #expect(try reopened.fetchCount(FetchDescriptor<Photo>()) == 3)
        }
    }

    @Test
    func retrying_after_a_rolled_back_creation_does_not_duplicate_records() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)

            // First attempt: create, then abandon it the way a failed save does.
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: try makeCurryDraft()
            )
            context.rollback()

            // Retry the identical draft and let this one land.
            _ = try RecipeFormOperations.createWithOutcome(
                context: context,
                draft: try makeCurryDraft()
            )
            try context.save()

            let reopened = try makeContext(at: url)
            // The abandoned attempt must leave nothing for the retry to collide
            // with: one recipe, and one tag record per distinct name.
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Curry"])
            #expect(try reopened.fetch(.ingredients(.all)).map(\.value).sorted() == ["Onion", "Rice"])
            #expect(try reopened.fetch(.categories(.all)).map(\.value) == ["Dinner"])
            #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == 2)
        }
    }

    // `rollback()` is context-wide, not mutation-scoped: it discards every
    // pending change, including ones the failed mutation never touched. Cookle
    // shares one main context across the app, so this pins the boundary the
    // form models depend on by holding drafts in value types rather than as
    // live edits on the stored objects.
    @Test
    func rollback_discards_unrelated_pending_edits_in_the_same_context() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let editedRecipe = makeRecipe(context: context, name: "Curry")
            let deletedRecipe = makeRecipe(context: context, name: "Salad")
            try context.save()

            // Another editor's unsaved change, unrelated to the mutation below.
            editedRecipe.update(
                content: makeContent(name: "Curry", note: "Edited elsewhere")
            )

            _ = RecipeOperations.deleteWithOutcome(
                context: context,
                recipe: deletedRecipe
            )
            context.rollback()

            let reopened = try makeContext(at: url)
            let notes = try reopened.fetch(.recipes(.all))
                .sorted { $0.name < $1.name }
                .map(\.note)
            #expect(notes == ["", ""])
        }
    }

    @Test
    func rollback_keeps_unrelated_edits_that_were_already_saved() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let editedRecipe = makeRecipe(context: context, name: "Curry")
            let deletedRecipe = makeRecipe(context: context, name: "Salad")
            try context.save()

            editedRecipe.update(
                content: makeContent(name: "Curry", note: "Saved elsewhere")
            )
            try context.save()

            _ = RecipeOperations.deleteWithOutcome(
                context: context,
                recipe: deletedRecipe
            )
            context.rollback()

            let reopened = try makeContext(at: url)
            let recipes = try reopened.fetch(.recipes(.all))
                .sorted { $0.name < $1.name }
            #expect(recipes.map(\.name) == ["Curry", "Salad"])
            #expect(recipes.first?.note == "Saved elsewhere")
        }
    }
}

private extension RecipeMutationRollbackPersistenceTests {
    /// Replaces every ingredient row and re-points the category relation, so a
    /// failed save has to undo more than one field.
    func makeReplacementCurryDraft() throws -> RecipeFormDraft {
        try RecipeFormOperations.makeDraft(
            input: .init(
                name: "Curry",
                photos: [],
                servingSize: "2",
                cookingTime: "30",
                ingredients: [
                    .init(ingredient: "Potato", amount: "3")
                ],
                steps: ["Chop.", "Simmer."],
                categories: ["Lunch"],
                note: "Weeknight"
            )
        )
    }
}
