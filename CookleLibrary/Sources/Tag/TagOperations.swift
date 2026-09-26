import SwiftData

/// Tag use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum TagOperations {
    /// Renames an ingredient and returns follow-up hints.
    public static func renameWithOutcome(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws -> MutationOutcome<Void> {
        try TagService.renameWithOutcome(
            context: context,
            ingredient: ingredient,
            value: value
        )
    }

    /// Renames a category and returns follow-up hints.
    public static func renameWithOutcome(
        context: ModelContext,
        category: Category,
        value: String
    ) throws -> MutationOutcome<Void> {
        try TagService.renameWithOutcome(
            context: context,
            category: category,
            value: value
        )
    }

    /// Deletes a category and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        category: Category
    ) -> MutationOutcome<Void> {
        TagService.deleteWithOutcome(
            context: context,
            category: category
        )
    }

    /// Deletes an unused ingredient and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        try TagService.deleteWithOutcome(
            context: context,
            ingredient: ingredient
        )
    }

    /// Describes what deleting `tag` affects, as values for a review.
    public static func deletionReview<T: Tag>(
        for tag: T
    ) -> TagDeletionReview<T> {
        TagService.deletionReview(
            for: tag
        )
    }

    /// Re-resolves the reviewed tag and describes what deleting it affects now.
    ///
    /// - Returns: `nil` when the tag no longer exists.
    public static func currentDeletionReview<T: Tag>(
        for review: TagDeletionReview<T>,
        context: ModelContext
    ) throws -> TagDeletionReview<T>? {
        try TagService.currentDeletionReview(
            for: review,
            context: context
        )
    }

    /// Deletes the reviewed category after re-resolving it, and returns follow-up hints.
    ///
    /// - Throws: `ReviewedMutationError` when the category is gone or the
    ///   recipes using it differ from the review. Neither case changes the store.
    public static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: TagDeletionReview<Category>
    ) throws -> MutationOutcome<Void> {
        try TagService.deleteWithOutcome(
            context: context,
            reviewed: review
        )
    }

    /// Deletes the reviewed unused ingredient after re-resolving it, and returns follow-up hints.
    ///
    /// - Throws: `ReviewedMutationError` when the ingredient is gone or the
    ///   recipes using it differ from the review, or
    ///   `TagOperationsError.ingredientInUse` when a recipe still uses it.
    public static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: TagDeletionReview<Ingredient>
    ) throws -> MutationOutcome<Void> {
        try TagService.deleteWithOutcome(
            context: context,
            reviewed: review
        )
    }

    /// Describes what merging the duplicates of `tag` into it affects, as values for a review.
    public static func mergeReview<T: Tag>(
        context: ModelContext,
        keeping tag: T
    ) throws -> TagMergeReview<T> {
        try TagService.mergeReview(
            context: context,
            keeping: tag
        )
    }

    /// Re-resolves the kept tag and describes what merging into it affects now.
    ///
    /// - Returns: `nil` when the kept tag no longer exists.
    public static func currentMergeReview<T: Tag>(
        for review: TagMergeReview<T>,
        context: ModelContext
    ) throws -> TagMergeReview<T>? {
        try TagService.currentMergeReview(
            for: review,
            context: context
        )
    }

    /// Merges the reviewed ingredient duplicates after re-resolving them, and returns follow-up hints.
    ///
    /// - Throws: `ReviewedMutationError` when the kept ingredient is gone or the
    ///   duplicates or moved recipes differ from the review.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        reviewed review: TagMergeReview<Ingredient>
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            reviewed: review
        )
    }

    /// Merges the reviewed category duplicates after re-resolving them, and returns follow-up hints.
    ///
    /// - Throws: `ReviewedMutationError` when the kept category is gone or the
    ///   duplicates or moved recipes differ from the review.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        reviewed review: TagMergeReview<Category>
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            reviewed: review
        )
    }

    /// Returns all tags that look equivalent to `tag` in the supplied collection.
    public static func duplicateTags<T: Tag>(
        matching tag: T,
        in tags: [T]
    ) -> [T] {
        TagService.duplicateTags(
            matching: tag,
            in: tags
        )
    }

    /// Returns one representative per duplicate-looking group in the supplied collection.
    public static func duplicateTags<T: Tag>(
        in tags: [T]
    ) -> [T] {
        TagService.duplicateTags(in: tags)
    }

    /// Merges duplicate-looking ingredients into the supplied ingredient.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: ingredient
        )
    }

    /// Merges duplicate-looking categories into the supplied category.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping category: Category
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: category
        )
    }
}
