@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins that tag deletion and merge apply only to the impact the user reviewed.
@MainActor
struct ReviewedTagMutationTests {
    let context: ModelContext = makeTestContext()

    @Test
    func category_review_lists_recipes_and_deletes_only_while_unchanged() throws {
        let category = try CookleLibrary.Category.create(context: context, value: "Dinner")
        for name in ["Soup", "Curry", "Pasta", "Stew"] {
            makeRecipe(name: name, categories: [category])
        }
        try context.save()

        let review = TagOperations.deletionReview(for: category)

        #expect(review.value == "Dinner")
        #expect(review.recipeCount == 4)
        #expect(review.recipeNameExamples == ["Curry", "Pasta", "Soup"])

        _ = try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try context.fetch(.categories(.all)).isEmpty)
        #expect(try context.fetch(.recipes(.all)).count == 4)
    }

    @Test
    func category_review_with_a_swapped_recipe_of_the_same_count_is_stale() throws {
        let category = try CookleLibrary.Category.create(context: context, value: "Dinner")
        let reviewedRecipe = makeRecipe(name: "Curry", categories: [category])
        let otherRecipe = makeRecipe(name: "Salad")
        try context.save()
        let review = TagOperations.deletionReview(for: category)

        reviewedRecipe.updateCategories([])
        otherRecipe.updateCategories([category])
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        }
        #expect(context.hasChanges == false)
        let refreshed = try #require(
            try TagOperations.currentDeletionReview(for: review, context: context)
        )
        #expect(refreshed.recipeCount == 1)
        #expect(refreshed.recipeNameExamples == ["Salad"])
    }

    @Test
    func renaming_a_reviewed_tag_requires_confirmation_again() throws {
        let category = try CookleLibrary.Category.create(context: context, value: "Dinner")
        try context.save()
        let review = TagOperations.deletionReview(for: category)
        category.update(value: "Lunch")
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        }
    }

    @Test
    func renaming_a_duplicate_without_changing_membership_invalidates_merge_review() throws {
        let kept = try CookleLibrary.Category.create(context: context, value: "Dinner")
        let duplicate = try CookleLibrary.Category.create(context: context, value: "dinner")
        try context.save()
        let review = try TagOperations.mergeReview(context: context, keeping: kept)
        duplicate.update(value: "DINNER")
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        }
    }

    @Test
    func deleting_a_category_twice_reports_it_missing() throws {
        let category = try CookleLibrary.Category.create(context: context, value: "Dinner")
        try context.save()
        let review = TagOperations.deletionReview(for: category)

        _ = try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try TagOperations.currentDeletionReview(for: review, context: context) == nil)
        #expect(throws: ReviewedMutationError.targetMissing) {
            try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        }
    }

    @Test
    func an_ingredient_that_became_used_after_review_is_not_deleted() throws {
        let ingredient = try Ingredient.create(context: context, value: "Salt")
        try context.save()
        let review = TagOperations.deletionReview(for: ingredient)
        #expect(review.recipeCount == .zero)

        makeRecipe(
            name: "Soup",
            ingredients: [makeIngredientObject(ingredient: ingredient, amount: "1 pinch")]
        )
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        }
        let refreshed = try #require(
            try TagOperations.currentDeletionReview(for: review, context: context)
        )
        #expect(throws: TagOperationsError.ingredientInUse("Salt")) {
            try TagOperations.deleteWithOutcome(context: context, reviewed: refreshed)
        }
        #expect(try context.fetch(.ingredients(.all)).count == 1)
    }

    @Test
    func an_unused_ingredient_is_deleted_after_an_unrelated_change() throws {
        let ingredient = try Ingredient.create(context: context, value: "Salt")
        try context.save()
        let review = TagOperations.deletionReview(for: ingredient)

        makeRecipe(name: "Unrelated")
        try context.save()

        _ = try TagOperations.deleteWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try context.fetch(.ingredients(.all)).isEmpty)
    }

    @Test
    func ingredient_merge_review_counts_duplicates_and_moved_recipes() throws {
        let kept = try Ingredient.create(context: context, value: "Eggs")
        let duplicate = try Ingredient.create(context: context, value: " eggs ")
        makeRecipe(name: "Omelette", ingredients: [makeIngredientObject(ingredient: kept, amount: "2")])
        makeRecipe(name: "Cake", ingredients: [makeIngredientObject(ingredient: duplicate, amount: "3")])
        try context.save()

        let review = try TagOperations.mergeReview(context: context, keeping: kept)

        #expect(review.keptValue == "Eggs")
        #expect(review.duplicateCount == 1)
        #expect(review.duplicateValueExamples == [" eggs "])
        #expect(review.recipeCount == 1)
        #expect(review.recipeNameExamples == ["Cake"])

        _ = try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(try context.fetch(.ingredients(.all)).map(\.value) == ["Eggs"])
        let amounts = try context.fetch(FetchDescriptor<IngredientObject>()).map(\.amount).sorted()
        #expect(amounts == ["2", "3"])
    }

    @Test
    func a_merge_review_is_stale_when_a_new_duplicate_appears() throws {
        let kept = try CookleLibrary.Category.create(context: context, value: "Dinner")
        let duplicate = try CookleLibrary.Category.create(context: context, value: "dinner")
        makeRecipe(name: "Curry", categories: [duplicate])
        try context.save()
        let review = try TagOperations.mergeReview(context: context, keeping: kept)

        let lateDuplicate = try CookleLibrary.Category.create(context: context, value: "DINNER")
        makeRecipe(name: "Stew", categories: [lateDuplicate])
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        }
        #expect(try context.fetch(.categories(.all)).count == 3)
        let refreshed = try #require(
            try TagOperations.currentMergeReview(for: review, context: context)
        )
        #expect(refreshed.duplicateCount == 2)
        #expect(refreshed.recipeNameExamples == ["Curry", "Stew"])
    }

    @Test
    func repeating_a_completed_merge_is_reported_as_changed_and_merges_nothing() throws {
        let kept = try CookleLibrary.Category.create(context: context, value: "Dinner")
        let duplicate = try CookleLibrary.Category.create(context: context, value: "dinner")
        makeRecipe(name: "Curry", categories: [duplicate])
        try context.save()
        let review = try TagOperations.mergeReview(context: context, keeping: kept)

        _ = try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        try context.save()

        #expect(throws: ReviewedMutationError.impactChanged) {
            try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        }
        let refreshed = try #require(
            try TagOperations.currentMergeReview(for: review, context: context)
        )
        #expect(refreshed.hasDuplicates == false)
        #expect(try context.fetch(.recipes(.all)).first?.categories?.map(\.value) == ["Dinner"])
    }

    @Test
    func a_merge_whose_kept_tag_was_deleted_is_reported_missing() throws {
        let kept = try CookleLibrary.Category.create(context: context, value: "Dinner")
        _ = try CookleLibrary.Category.create(context: context, value: "dinner")
        try context.save()
        let review = try TagOperations.mergeReview(context: context, keeping: kept)

        context.delete(kept)
        try context.save()

        #expect(throws: ReviewedMutationError.targetMissing) {
            try TagOperations.mergeDuplicatesWithOutcome(context: context, reviewed: review)
        }
        #expect(try context.fetch(.categories(.all)).map(\.value) == ["dinner"])
    }
}

private extension ReviewedTagMutationTests {
    enum TestValues {
        static let servingSize = 2
        static let cookingTimeMinutes = 30
    }

    func makeIngredientObject(
        ingredient: Ingredient,
        amount: String
    ) -> IngredientObject {
        IngredientObject.restore(
            context: context,
            ingredient: ingredient,
            amount: amount,
            order: 1,
            timestamps: .init(
                created: .now,
                modified: .now
            )
        )
    }

    @discardableResult
    func makeRecipe(
        name: String,
        ingredients: [IngredientObject] = [],
        categories: [CookleLibrary.Category] = []
    ) -> Recipe {
        Recipe.create(
            context: context,
            content: .init(
                name: name,
                photos: [],
                servingSize: TestValues.servingSize,
                cookingTime: TestValues.cookingTimeMinutes,
                ingredients: ingredients,
                steps: [],
                categories: categories,
                note: ""
            )
        )
    }
}
