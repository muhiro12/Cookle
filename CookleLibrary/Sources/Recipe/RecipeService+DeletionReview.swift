import SwiftData

extension RecipeService {
    /// Describes what deleting `recipe` removes.
    static func deletionReview(
        for recipe: Recipe
    ) -> RecipeDeletionReview {
        .init(recipe: recipe)
    }

    /// Re-resolves the reviewed recipe and describes what deleting it removes now.
    ///
    /// - Returns: `nil` when the recipe no longer exists.
    static func currentDeletionReview(
        for review: RecipeDeletionReview,
        context: ModelContext
    ) throws -> RecipeDeletionReview? {
        try context.fetchFirst(
            .recipes(.idIs(review.recipeID))
        )
        .map(RecipeDeletionReview.init)
    }

    /// Deletes the reviewed recipe only when its impact still matches the review.
    static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: RecipeDeletionReview
    ) throws -> MutationOutcome<Void> {
        guard let recipe = try context.fetchFirst(
            .recipes(.idIs(review.recipeID))
        ) else {
            throw ReviewedMutationError.targetMissing
        }
        guard deletionReview(for: recipe).hasSameImpact(as: review) else {
            throw ReviewedMutationError.impactChanged
        }

        return deleteWithOutcome(
            context: context,
            recipe: recipe
        )
    }
}
