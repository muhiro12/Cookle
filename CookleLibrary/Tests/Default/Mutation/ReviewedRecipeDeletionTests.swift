@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins that a recipe deletion applies only to the impact the user reviewed.
@MainActor
struct ReviewedRecipeDeletionTests {
    let context: ModelContext = makeTestContext()

    @Test
    func review_counts_every_meal_row_and_lists_a_bounded_most_recent_sample() throws {
        let recipe = makeRecipe(name: "Curry")
        for day in 1...5 {
            makeDiary(day: day, meals: [(recipe, .dinner)])
        }
        try context.save()

        let review = RecipeOperations.deletionReview(for: recipe)

        #expect(review.recipeName == "Curry")
        #expect(review.mealRowCount == 5)
        #expect(review.mealRowExamples.count == 3)
        #expect(review.mealRowExamples.map(\.date) == [date(day: 5), date(day: 4), date(day: 3)])
        #expect(review.mealRowExamples.allSatisfy { mealRow in
            mealRow.type == .dinner
        })
    }

    @Test
    func an_unchanged_review_deletes_the_recipe_and_its_meal_rows_but_keeps_diaries() throws {
        let recipe = makeRecipe(name: "Curry")
        makeDiary(day: 1, meals: [(recipe, .lunch)])
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)

        _ = try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try context.fetch(.recipes(.all)).isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<DiaryObject>()) == .zero)
        #expect(try context.fetchCount(FetchDescriptor<Diary>()) == 1)
    }

    @Test
    func a_different_affected_set_of_the_same_size_is_stale_and_changes_nothing() throws {
        let recipe = makeRecipe(name: "Curry")
        let firstDiary = makeDiary(day: 1, meals: [(recipe, .lunch)])
        makeDiary(day: 2, meals: [])
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)

        // The reviewed row goes away and a new row takes its place on another day.
        let secondDiary = try #require(try context.fetch(FetchDescriptor<Diary>()).first { diary in
            diary.persistentModelID != firstDiary.persistentModelID
        })
        for object in firstDiary.objects ?? [] {
            context.delete(object)
        }
        secondDiary.update(
            content: .init(
                date: secondDiary.date,
                objects: [
                    DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: 1)
                ],
                note: ""
            )
        )
        try context.save()

        let refreshed = try #require(
            try RecipeOperations.currentDeletionReview(for: review, context: context)
        )
        #expect(refreshed.mealRowCount == review.mealRowCount)
        #expect(refreshed.hasSameImpact(as: review) == false)
        #expect(throws: ReviewedMutationError.impactChanged) {
            try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        }
        #expect(context.hasChanges == false)
        #expect(try context.fetch(.recipes(.all)).count == 1)

        _ = try RecipeOperations.deleteWithOutcome(context: context, reviewed: refreshed)
        try context.save()
        #expect(try context.fetch(.recipes(.all)).isEmpty)
    }

    @Test
    func unrelated_changes_do_not_require_a_new_review() throws {
        let recipe = makeRecipe(name: "Curry")
        makeDiary(day: 1, meals: [(recipe, .lunch)])
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)

        let otherRecipe = makeRecipe(name: "Salad")
        makeDiary(day: 2, meals: [(otherRecipe, .dinner)])
        try context.save()

        _ = try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try context.fetch(.recipes(.all)).map(\.name) == ["Salad"])
    }

    @Test
    func renaming_the_reviewed_recipe_requires_confirmation_again() throws {
        let recipe = makeRecipe(name: "Curry")
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)
        recipe.update(content: recipeContent(name: "Beef Curry"))
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        }
    }

    @Test
    func moving_the_same_meal_rows_to_another_date_requires_confirmation_again() throws {
        let recipe = makeRecipe(name: "Curry")
        let diary = makeDiary(day: 1, meals: [(recipe, .lunch)])
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)
        diary.update(content: .init(date: date(day: 2), objects: diary.objects ?? [], note: ""))
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        }
    }

    @Test
    func a_missing_recipe_is_reported_without_touching_the_store_and_repeating_is_a_no_op() throws {
        let recipe = makeRecipe(name: "Curry")
        let survivor = makeRecipe(name: "Salad")
        try context.save()
        let review = RecipeOperations.deletionReview(for: recipe)

        _ = try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try RecipeOperations.currentDeletionReview(for: review, context: context) == nil)
        #expect(throws: ReviewedMutationError.targetMissing) {
            try RecipeOperations.deleteWithOutcome(context: context, reviewed: review)
        }
        #expect(context.hasChanges == false)
        #expect(try context.fetch(.recipes(.all)).map(\.persistentModelID) == [survivor.persistentModelID])
    }

    @Test
    func a_meal_row_another_context_adds_after_review_is_detected() throws {
        try withDiskStore { url in
            let writer = try makeContext(at: url)
            addMealRow(
                for: Recipe.create(context: writer, content: recipeContent(name: "Curry")),
                day: 1,
                context: writer
            )
            try writer.save()

            let reviewer = try makeContext(at: url)
            let reviewedRecipe = try #require(try reviewer.fetch(.recipes(.all)).first)
            let review = RecipeOperations.deletionReview(for: reviewedRecipe)
            #expect(review.mealRowCount == 1)

            let other = try makeContext(at: url)
            addMealRow(
                for: try #require(try other.fetch(.recipes(.all)).first),
                day: 2,
                context: other
            )
            try other.save()

            #expect(throws: ReviewedMutationError.impactChanged) {
                try RecipeOperations.deleteWithOutcome(context: reviewer, reviewed: review)
            }
            let refreshed = try #require(
                try RecipeOperations.currentDeletionReview(for: review, context: reviewer)
            )
            #expect(refreshed.mealRowCount == 2)
        }
    }
}

private extension ReviewedRecipeDeletionTests {
    enum TestValues {
        static let year = 2_026
        static let month = 9
        static let hour = 12
        static let servingSize = 2
        static let cookingTimeMinutes = 30
    }

    func date(day: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            from: .init(
                timeZone: .gmt,
                year: TestValues.year,
                month: TestValues.month,
                day: day,
                hour: TestValues.hour
            )
        ) ?? .distantPast
    }

    func addMealRow(
        for recipe: Recipe,
        day: Int,
        context: ModelContext
    ) {
        _ = Diary.create(
            context: context,
            content: .init(
                date: date(day: day),
                objects: [
                    DiaryObject.create(context: context, recipe: recipe, type: .dinner, order: 1)
                ],
                note: ""
            )
        )
    }

    func recipeContent(name: String) -> RecipeContent {
        .init(
            name: name,
            photos: [],
            servingSize: TestValues.servingSize,
            cookingTime: TestValues.cookingTimeMinutes,
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    @discardableResult
    func makeRecipe(name: String) -> Recipe {
        Recipe.create(
            context: context,
            content: recipeContent(name: name)
        )
    }

    @discardableResult
    func makeDiary(
        day: Int,
        meals: [(Recipe, DiaryObjectType)]
    ) -> Diary {
        Diary.create(
            context: context,
            content: .init(
                date: date(day: day),
                objects: meals.enumerated().map { index, meal in
                    DiaryObject.create(
                        context: context,
                        recipe: meal.0,
                        type: meal.1,
                        order: index + 1
                    )
                },
                note: ""
            )
        )
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
}
