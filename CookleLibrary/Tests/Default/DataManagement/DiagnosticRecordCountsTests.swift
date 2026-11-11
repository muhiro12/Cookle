@testable import CookleLibrary
import SwiftData
import Testing

@MainActor
struct DiagnosticRecordCountsTests: MutationRollbackTestSupport {
    @Test
    func inspectionReadsSavedGraphWithoutChangingRecordsOrPendingEdits() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            let recipe = try DeletionPolicyAuditSupport.makeRecipe(
                context: context,
                name: "Private recipe",
                ingredients: [.init(ingredient: "Salt", amount: "1 tsp")],
                categories: ["Dinner"]
            )
            _ = try DiaryOperations.createWithOutcome(
                context: context, input: .init(date: Self.day, dinners: [recipe], note: "Private note")
            )
            try context.save()
            let counts = try DiagnosticRecordCounts.read(container: context.container)
            #expect(counts.recipes == 1)
            #expect(counts.diaries == 1)
            #expect(counts.diaryObjects == 1)
            #expect(counts.ingredients == 1)
            #expect(counts.ingredientObjects == 1)
            #expect(counts.categories == 1)
            #expect(counts.photos == 0)
            #expect(counts.photoObjects == 0)
            _ = makeRecipe(context: context, name: "Pending")
            #expect(try DiagnosticRecordCounts.read(container: context.container) == counts)
            #expect(context.hasChanges)
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Private recipe"])
            #expect(try reopened.fetch(.diaries(.all)).map(\.note) == ["Private note"])
        }
    }
}
