@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DetachedObjectCleanupServiceTests {
    @Test
    func runIfNeeded_deletesDetachedObjectRows_andKeepsSharedRoots() throws {
        let context = makeTestContext()
        let recipe = Recipe.create(
            context: context,
            name: "Cleanup Target",
            photos: [],
            servingSize: 1,
            cookingTime: 10,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
        _ = PhotoObject.create(
            context: context,
            photoData: .init(
                data: Data("detached-photo".utf8),
                source: .photosPicker
            ),
            order: 1
        )
        _ = IngredientObject.create(
            context: context,
            ingredient: "Salt",
            amount: "1 tsp",
            order: 1
        )
        _ = DiaryObject.create(
            context: context,
            recipe: recipe,
            type: .breakfast,
            order: 1
        )
        try context.save()

        var isCleanupCompleted = false
        let outcome = try DetachedObjectCleanupService.runIfNeeded(
            context: context,
            isCompleted: {
                isCleanupCompleted
            },
            markCompleted: {
                isCleanupCompleted = true
            }
        )

        let report: DetachedObjectCleanupService.Report
        switch outcome {
        case .performed(let performedReport):
            report = performedReport
        case .skippedAlreadyCompleted:
            Issue.record("Cleanup unexpectedly skipped.")
            return
        }

        #expect(report.deletedDiaryObjectCount == 1)
        #expect(report.deletedPhotoObjectCount == 1)
        #expect(report.deletedIngredientObjectCount == 1)
        #expect(isCleanupCompleted)
        #expect(try context.fetchCount(FetchDescriptor<DiaryObject>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<PhotoObject>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<IngredientObject>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 1)
        let remainingPhoto = try #require(
            context.fetch(.photos(.all)).first
        )
        let remainingIngredient = try #require(
            context.fetch(.ingredients(.all)).first
        )

        #expect(try context.fetchCount(FetchDescriptor<Photo>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Ingredient>()) == 1)
        #expect(remainingPhoto.objects.orEmpty.isEmpty)
        #expect(remainingIngredient.objects.orEmpty.isEmpty)
    }

    @Test
    func runIfNeeded_skips_whenCleanupWasAlreadyCompleted() throws {
        let context = makeTestContext()
        _ = PhotoObject.create(
            context: context,
            photoData: .init(
                data: Data("existing-detached-photo".utf8),
                source: .photosPicker
            ),
            order: 1
        )
        try context.save()

        var isCleanupCompleted = true
        let outcome = try DetachedObjectCleanupService.runIfNeeded(
            context: context,
            isCompleted: {
                isCleanupCompleted
            },
            markCompleted: {
                isCleanupCompleted = true
            }
        )

        #expect(outcome == .skippedAlreadyCompleted)
        #expect(try context.fetchCount(FetchDescriptor<PhotoObject>()) == 1)
        #expect(isCleanupCompleted)
    }

    @Test
    func runIfNeeded_isNoOp_afterFirstSuccessfulRun() throws {
        let context = makeTestContext()
        _ = PhotoObject.create(
            context: context,
            photoData: .init(
                data: Data("one-time-photo".utf8),
                source: .photosPicker
            ),
            order: 1
        )
        try context.save()

        var isCleanupCompleted = false
        let firstOutcome = try DetachedObjectCleanupService.runIfNeeded(
            context: context,
            isCompleted: {
                isCleanupCompleted
            },
            markCompleted: {
                isCleanupCompleted = true
            }
        )
        let secondOutcome = try DetachedObjectCleanupService.runIfNeeded(
            context: context,
            isCompleted: {
                isCleanupCompleted
            },
            markCompleted: {
                isCleanupCompleted = true
            }
        )

        let firstReport: DetachedObjectCleanupService.Report
        switch firstOutcome {
        case .performed(let performedReport):
            firstReport = performedReport
        case .skippedAlreadyCompleted:
            Issue.record("First cleanup unexpectedly skipped.")
            return
        }

        #expect(firstReport.deletedPhotoObjectCount == 1)
        #expect(secondOutcome == .skippedAlreadyCompleted)
        #expect(try context.fetchCount(FetchDescriptor<PhotoObject>()) == 0)
    }
}
