@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiagnosticDeletionPolicyTests: MutationRollbackTestSupport {
    @Test
    func used_ingredient_is_rejected_without_losing_amount_rows() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = try DeletionPolicyAuditSupport.makeRecipe(
                context: context, name: "Target", ingredients: [.init(ingredient: "Salt", amount: "1 tsp")]
            )
            try context.save()
            let ingredient = try #require((recipe.ingredients ?? []).first)
            #expect(throws: TagOperationsError.ingredientInUse("Salt")) {
                try DiagnosticOperations.deleteWithOutcome(context: context, model: ingredient)
            }
            #expect(context.hasChanges == false)
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(FetchDescriptor<IngredientObject>()).map(\.amount) == ["1 tsp"])
            #expect(try reopened.fetch(.ingredients(.all)).map(\.value) == ["Salt"])
        }
    }

    @Test
    func unused_ingredient_and_category_can_be_deleted() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let ingredient = try Ingredient.create(context: context, value: "Unused")
            let recipe = try DeletionPolicyAuditSupport.makeRecipe(
                context: context, name: "Target", categories: ["Dinner"]
            )
            let category = try #require((recipe.categories ?? []).first)
            try context.save()
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: ingredient)
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: category)
            try context.save()
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetchCount(FetchDescriptor<Ingredient>()) == 0)
            #expect(try reopened.fetchCount(FetchDescriptor<CookleLibrary.Category>()) == 0)
            let retainedRecipe = try #require(try reopened.fetch(.recipes(.all)).first)
            #expect((retainedRecipe.categories ?? []).isEmpty)
        }
    }

    @Test
    func explicit_detached_row_deletion_keeps_shared_roots() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Target")
            let diaryRow = DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: 1)
            let photoRow = try PhotoObject.create(
                context: context, photoData: DeletionPolicyAuditSupport.makePhotoData("detached"), order: 1
            )
            let ingredientRow = try IngredientObject.create(
                context: context, ingredient: "Salt", amount: "1 tsp", order: 1
            )
            try context.save()
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: diaryRow)
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: photoRow)
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: ingredientRow)
            try context.save()
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetchCount(FetchDescriptor<DiaryObject>()) == 0)
            #expect(try reopened.fetchCount(FetchDescriptor<PhotoObject>()) == 0)
            #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == 0)
            #expect(try reopened.fetchCount(FetchDescriptor<Recipe>()) == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<Photo>()) == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        }
    }

    @Test
    func cross_context_stale_row_is_rejected_before_parent_changes() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            _ = try DeletionPolicyAuditSupport.makeRecipe(
                context: writer, name: "Target", ingredients: [.init(ingredient: "Salt", amount: "1 tsp")]
            )
            try writer.save()
            let inspector = try makeContext(at: url)
            let staleRow = try #require(try inspector.fetch(FetchDescriptor<IngredientObject>()).first)
            _ = staleRow.amount
            let deleter = try makeContext(at: url)
            let liveRow = try #require(try deleter.fetch(FetchDescriptor<IngredientObject>()).first)
            _ = try DiagnosticOperations.deleteWithOutcome(context: deleter, model: liveRow)
            try deleter.save()

            #expect(throws: ReviewedMutationError.targetMissing) {
                try DiagnosticOperations.deleteWithOutcome(context: inspector, model: staleRow)
            }
            #expect(inspector.hasChanges == false)
            let reopened = try makeContext(at: url)
            let recipe = try #require(try reopened.fetch(.recipes(.all)).first)
            #expect((recipe.ingredients ?? []).isEmpty)
            #expect((recipe.ingredientObjects ?? []).isEmpty)
        }
    }

    @Test
    func rollback_restores_deleted_ingredient_row_and_derived_relation() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = try DeletionPolicyAuditSupport.makeRecipe(
                context: context, name: "Target", ingredients: [.init(ingredient: "Salt", amount: "1 tsp")]
            )
            try context.save()
            let originalTimestamp = recipe.modifiedTimestamp
            let row = try #require((recipe.ingredientObjects ?? []).first)
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: row)
            context.rollback()

            let restoredRecipe = try #require(try context.fetch(.recipes(.all)).first)
            #expect((restoredRecipe.ingredients ?? []).map(\.value) == ["Salt"])
            #expect((restoredRecipe.ingredientObjects ?? []).map(\.amount) == ["1 tsp"])
            #expect(restoredRecipe.modifiedTimestamp == originalTimestamp)
            #expect(context.hasChanges == false)
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(FetchDescriptor<IngredientObject>()).map(\.amount) == ["1 tsp"])
        }
    }

    @Test
    func rollback_restores_deleted_diary_row_and_derived_relation() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = makeRecipe(context: context, name: "Target")
            let diary = try DiaryOperations.createWithOutcome(
                context: context, input: .init(date: Self.day, dinners: [recipe], note: "Keep this note")
            ).value
            try context.save()
            let originalTimestamp = diary.modifiedTimestamp
            let row = try #require((diary.objects ?? []).first)
            _ = try DiagnosticOperations.deleteWithOutcome(context: context, model: row)
            context.rollback()

            let restoredDiary = try #require(try context.fetch(.diaries(.all)).first)
            #expect((restoredDiary.recipes ?? []).map(\.name) == ["Target"])
            #expect((restoredDiary.objects ?? []).map(\.type) == [.dinner])
            #expect(restoredDiary.modifiedTimestamp == originalTimestamp)
            #expect(context.hasChanges == false)
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(FetchDescriptor<DiaryObject>()).map(\.type) == [.dinner])
        }
    }
}
