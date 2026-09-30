@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DiagnosticChildDeletionTests: MutationRollbackTestSupport {
    private enum Expected {
        static let retainedMealCount = 2
        static let recipeCount = 2
        static let initiallyMatchingRecipeCount = 2
    }

    @Test
    func photo_row_deletion_keeps_shared_assets_and_rebuilds_flattened_photos() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let photoData = DeletionPolicyAuditSupport.makePhotoData("shared")
            let recipe = try DeletionPolicyAuditSupport.makeRecipe(
                context: context, name: "Target", photos: [photoData, photoData]
            )
            _ = try DeletionPolicyAuditSupport.makeRecipe(
                context: context, name: "Other", photos: [photoData]
            )
            try context.save()
            let previousTimestamp = recipe.modifiedTimestamp
            let firstRow = try #require(recipe.orderedPhotoObjects.first)

            let firstOutcome = try DiagnosticOperations.deleteWithOutcome(context: context, model: firstRow)
            try context.save()
            let afterFirst = try makeContext(at: url)
            let target = try requiredRecipe(named: "Target", context: afterFirst)
            #expect(target.orderedPhotoObjects.count == 1)
            #expect((target.photos ?? []).isEmpty == false)
            #expect(target.modifiedTimestamp > previousTimestamp)
            #expect(firstOutcome.effects == [.recipeDataChanged, .notificationPlanChanged])

            let lastRow = try #require(target.orderedPhotoObjects.first)
            _ = try DiagnosticOperations.deleteWithOutcome(context: afterFirst, model: lastRow)
            try afterFirst.save()
            let reopened = try makeContext(at: url)
            let finalTarget = try requiredRecipe(named: "Target", context: reopened)
            let other = try requiredRecipe(named: "Other", context: reopened)
            #expect(finalTarget.orderedPhotoObjects.isEmpty)
            #expect((finalTarget.photos ?? []).isEmpty)
            #expect(other.orderedPhotoObjects.count == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<Photo>()) == 1)
            #expect(try reopened.fetchCount(FetchDescriptor<PhotoObject>()) == 1)
        }
    }

    @Test
    func ingredient_row_deletion_preserves_amounts_and_updates_search_membership() throws {
        try withDiskStore { url in
            try verify_ingredient_row_deletion_preserves_amounts_and_updates_search_membership(at: url)
        }
    }

    @Test
    func diary_row_deletion_rebuilds_recipe_links_without_deleting_recipes() throws {
        try withDiskStore { url in
            try verify_diary_row_deletion_rebuilds_recipe_links_without_deleting_recipes(at: url)
        }
    }
}

private extension DiagnosticChildDeletionTests {
    func verify_diary_row_deletion_rebuilds_recipe_links_without_deleting_recipes(at url: URL) throws {
        let context = try makeContext(at: url)
        let targetRecipe = makeRecipe(context: context, name: "Target")
        let otherRecipe = makeRecipe(context: context, name: "Other")
        let diary = try DiaryOperations.createWithOutcome(
            context: context,
            input: .init(
                date: Self.day,
                breakfasts: [targetRecipe],
                lunches: [targetRecipe],
                dinners: [otherRecipe],
                note: "Keep this note"
            )
        ).value
        try context.save()
        let previousTimestamp = diary.modifiedTimestamp
        let firstRow = try #require((diary.objects ?? []).first { row in
            row.type == .breakfast
        })

        let outcome = try DiagnosticOperations.deleteWithOutcome(context: context, model: firstRow)
        try context.save()
        let afterFirst = try makeContext(at: url)
        let currentDiary = try #require(try afterFirst.fetch(.diaries(.all)).first)
        #expect((currentDiary.objects ?? []).count == Expected.retainedMealCount)
        #expect(Set((currentDiary.recipes ?? []).map(\.name)) == ["Target", "Other"])
        #expect(currentDiary.modifiedTimestamp > previousTimestamp)
        #expect(outcome.effects == [.recipeDataChanged, .diaryDataChanged, .notificationPlanChanged])

        let lastTargetRow = try #require((currentDiary.objects ?? []).first { row in
            row.recipe?.name == "Target"
        })
        _ = try DiagnosticOperations.deleteWithOutcome(context: afterFirst, model: lastTargetRow)
        try afterFirst.save()
        let reopened = try makeContext(at: url)
        let finalDiary = try #require(try reopened.fetch(.diaries(.all)).first)
        let finalRecipe = try requiredRecipe(named: "Target", context: reopened)
        #expect((finalDiary.objects ?? []).count == 1)
        #expect((finalDiary.recipes ?? []).map(\.name) == ["Other"])
        #expect((finalRecipe.diaries ?? []).isEmpty)
        #expect((finalRecipe.diaryObjects ?? []).isEmpty)
        #expect(finalDiary.date == Self.day)
        #expect(finalDiary.note == "Keep this note")
        #expect(try reopened.fetchCount(FetchDescriptor<Recipe>()) == Expected.recipeCount)
    }

    func verify_ingredient_row_deletion_preserves_amounts_and_updates_search_membership(at url: URL) throws {
        let context = try makeContext(at: url)
        let recipe = try DeletionPolicyAuditSupport.makeRecipe(
            context: context, name: "Target", ingredients: [
                .init(ingredient: "Salt", amount: "1 tsp"),
                .init(ingredient: "Salt", amount: "2 tsp")
            ]
        )
        _ = try DeletionPolicyAuditSupport.makeRecipe(
            context: context, name: "Other", ingredients: [.init(ingredient: "Salt", amount: "3 tsp")]
        )
        try context.save()
        let previousTimestamp = recipe.modifiedTimestamp
        let firstRow = try #require((recipe.ingredientObjects ?? []).first { row in
            row.amount == "1 tsp"
        })

        let outcome = try DiagnosticOperations.deleteWithOutcome(context: context, model: firstRow)
        try context.save()
        let afterFirst = try makeContext(at: url)
        let target = try requiredRecipe(named: "Target", context: afterFirst)
        let lastRow = try #require((target.ingredientObjects ?? []).first)
        #expect(lastRow.amount == "2 tsp")
        #expect((target.ingredients ?? []).map(\.value) == ["Salt"])
        #expect(target.modifiedTimestamp > previousTimestamp)
        #expect(try afterFirst.fetch(.recipes(.anyTextMatches("Salt"))).count == Expected.initiallyMatchingRecipeCount)
        #expect(outcome.effects == [.recipeDataChanged, .notificationPlanChanged])

        _ = try DiagnosticOperations.deleteWithOutcome(context: afterFirst, model: lastRow)
        try afterFirst.save()
        let reopened = try makeContext(at: url)
        let finalTarget = try requiredRecipe(named: "Target", context: reopened)
        let other = try requiredRecipe(named: "Other", context: reopened)
        #expect((finalTarget.ingredientObjects ?? []).isEmpty)
        #expect((finalTarget.ingredients ?? []).isEmpty)
        #expect((other.ingredientObjects ?? []).map(\.amount) == ["3 tsp"])
        #expect(try reopened.fetch(.recipes(.anyTextMatches("Salt"))).map(\.name) == ["Other"])
        #expect(try reopened.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        #expect(try reopened.fetchCount(FetchDescriptor<IngredientObject>()) == 1)
    }

    func requiredRecipe(named name: String, context: ModelContext) throws -> Recipe {
        try #require(try context.fetch(.recipes(.all)).first { recipe in
            recipe.name == name
        })
    }
}
