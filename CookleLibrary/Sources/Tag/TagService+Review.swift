import SwiftData

extension TagService {
    /// Describes what deleting `tag` affects.
    static func deletionReview<T: Tag>(
        for tag: T
    ) -> TagDeletionReview<T> {
        .init(tag: tag)
    }

    /// Re-resolves the reviewed tag and describes what deleting it affects now.
    ///
    /// - Returns: `nil` when the tag no longer exists.
    static func currentDeletionReview<T: Tag>(
        for review: TagDeletionReview<T>,
        context: ModelContext
    ) throws -> TagDeletionReview<T>? {
        try resolvedTag(
            T.self,
            id: review.tagID,
            context: context
        )
        .map(TagDeletionReview.init)
    }

    /// Deletes the reviewed category only when the recipes using it still match the review.
    static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: TagDeletionReview<Category>
    ) throws -> MutationOutcome<Void> {
        let category = try reviewedTag(
            for: review,
            context: context
        )
        return deleteWithOutcome(
            context: context,
            category: category
        )
    }

    /// Deletes the reviewed ingredient only when it is still unused and unchanged.
    static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: TagDeletionReview<Ingredient>
    ) throws -> MutationOutcome<Void> {
        let ingredient = try reviewedTag(
            for: review,
            context: context
        )
        return try deleteWithOutcome(
            context: context,
            ingredient: ingredient
        )
    }

    /// Describes what merging the duplicates of `tag` into it affects.
    static func mergeReview<T: Tag>(
        context: ModelContext,
        keeping tag: T
    ) throws -> TagMergeReview<T> {
        let duplicates = duplicateTags(
            matching: tag,
            in: try context.fetch(T.descriptor(.all))
        )
        .filter { duplicate in
            duplicate.persistentModelID != tag.persistentModelID
        }
        return .init(
            keeping: tag,
            duplicates: duplicates,
            affectedRecipes: duplicates.flatMap { duplicate in
                mergedRecipes(of: duplicate)
            }
        )
    }

    /// Re-resolves the kept tag and describes what merging into it affects now.
    ///
    /// - Returns: `nil` when the kept tag no longer exists.
    static func currentMergeReview<T: Tag>(
        for review: TagMergeReview<T>,
        context: ModelContext
    ) throws -> TagMergeReview<T>? {
        guard let tag = try resolvedTag(
            T.self,
            id: review.keptTagID,
            context: context
        ) else {
            return nil
        }

        return try mergeReview(
            context: context,
            keeping: tag
        )
    }

    /// Merges the reviewed ingredient duplicates only when they still match the review.
    static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        reviewed review: TagMergeReview<Ingredient>
    ) throws -> MutationOutcome<Void> {
        let ingredient = try reviewedTag(
            for: review,
            context: context
        )
        return try mergeDuplicatesWithOutcome(
            context: context,
            keeping: ingredient
        )
    }

    /// Merges the reviewed category duplicates only when they still match the review.
    static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        reviewed review: TagMergeReview<Category>
    ) throws -> MutationOutcome<Void> {
        let category = try reviewedTag(
            for: review,
            context: context
        )
        return try mergeDuplicatesWithOutcome(
            context: context,
            keeping: category
        )
    }
}

private extension TagService {
    static func resolvedTag<T: Tag>(
        _: T.Type,
        id: PersistentIdentifier,
        context: ModelContext
    ) throws -> T? {
        try context.fetchFirst(
            T.descriptor(.idIs(id))
        )
    }

    static func reviewedTag<T: Tag>(
        for review: TagDeletionReview<T>,
        context: ModelContext
    ) throws -> T {
        guard let tag = try resolvedTag(
            T.self,
            id: review.tagID,
            context: context
        ) else {
            throw ReviewedMutationError.targetMissing
        }
        guard deletionReview(for: tag).hasSameImpact(as: review) else {
            throw ReviewedMutationError.impactChanged
        }

        return tag
    }

    static func reviewedTag<T: Tag>(
        for review: TagMergeReview<T>,
        context: ModelContext
    ) throws -> T {
        guard let tag = try resolvedTag(
            T.self,
            id: review.keptTagID,
            context: context
        ) else {
            throw ReviewedMutationError.targetMissing
        }
        guard try mergeReview(context: context, keeping: tag).hasSameImpact(as: review) else {
            throw ReviewedMutationError.impactChanged
        }

        return tag
    }

    /// Recipes a merge moves from `duplicate` to the kept tag, matching how
    /// each tag type is reassigned.
    static func mergedRecipes<T: Tag>(
        of duplicate: T
    ) -> [Recipe] {
        if let ingredient = duplicate as? Ingredient {
            return (ingredient.objects ?? []).compactMap(\.recipe)
        }

        return duplicate.recipes ?? []
    }
}
