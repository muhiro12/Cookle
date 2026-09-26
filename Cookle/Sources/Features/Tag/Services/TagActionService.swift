import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class TagActionService {
    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init(notificationService: NotificationService) {
        let synchronizeNotifications: CookleMutationEffectAdapter.NotificationSynchronizer = {
            await notificationService.synchronizeScheduledSuggestions()
        }
        effectAdapter = CookleMutationEffectAdapter.make(
            synchronizeNotifications: synchronizeNotifications
        )
    }

    @discardableResult
    func rename(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "renameIngredient",
            context: context
        ) {
            try TagOperations.renameWithOutcome(
                context: context,
                ingredient: ingredient,
                value: value
            )
        }
    }

    @discardableResult
    func rename(
        context: ModelContext,
        category: Category,
        value: String
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "renameCategory",
            context: context
        ) {
            try TagOperations.renameWithOutcome(
                context: context,
                category: category,
                value: value
            )
        }
    }

    @discardableResult
    func rename<T: Tag>(
        context: ModelContext,
        tag: T,
        value: String
    ) async throws -> MutationOutcome<Void> {
        if let ingredient = tag as? Ingredient {
            return try await rename(
                context: context,
                ingredient: ingredient,
                value: value
            )
        }

        if let category = tag as? Category {
            return try await rename(
                context: context,
                category: category,
                value: value
            )
        }

        throw CookleActionError.unsupportedTagType(
            String(describing: T.self)
        )
    }

    /// Deletes the reviewed category when the recipes using it still match the review.
    func delete(
        context: ModelContext,
        reviewed review: TagDeletionReview<Category>
    ) async throws -> ReviewedMutationResult<TagDeletionReview<Category>> {
        guard let currentReview = try TagOperations.currentDeletionReview(
            for: review,
            context: context
        ) else {
            return .targetMissing
        }
        guard currentReview.hasSameImpact(as: review) else {
            return .changed(currentReview)
        }

        _ = try await run(
            name: "deleteCategory",
            context: context
        ) {
            try TagOperations.deleteWithOutcome(
                context: context,
                reviewed: review
            )
        }
        return .applied
    }

    /// Deletes the reviewed ingredient when it is still unused and unchanged.
    func delete(
        context: ModelContext,
        reviewed review: TagDeletionReview<Ingredient>
    ) async throws -> ReviewedMutationResult<TagDeletionReview<Ingredient>> {
        guard let currentReview = try TagOperations.currentDeletionReview(
            for: review,
            context: context
        ) else {
            return .targetMissing
        }
        guard currentReview.hasSameImpact(as: review) else {
            return .changed(currentReview)
        }

        _ = try await run(
            name: "deleteIngredient",
            context: context
        ) {
            try TagOperations.deleteWithOutcome(
                context: context,
                reviewed: review
            )
        }
        return .applied
    }

    /// Merges the reviewed duplicates when they and the recipes they move still match the review.
    func mergeDuplicates<T: Tag>(
        context: ModelContext,
        reviewed review: TagMergeReview<T>
    ) async throws -> ReviewedMutationResult<TagMergeReview<T>> {
        guard let currentReview = try TagOperations.currentMergeReview(
            for: review,
            context: context
        ) else {
            return .targetMissing
        }
        guard currentReview.hasSameImpact(as: review) else {
            return .changed(currentReview)
        }

        _ = try await run(
            name: review is TagMergeReview<Ingredient>
                ? "mergeDuplicateIngredients"
                : "mergeDuplicateCategories",
            context: context
        ) {
            try Self.mergeDuplicatesWithOutcome(
                context: context,
                reviewed: review
            )
        }
        return .applied
    }
}

private extension TagActionService {
    static func mergeDuplicatesWithOutcome<T: Tag>(
        context: ModelContext,
        reviewed review: TagMergeReview<T>
    ) throws -> MutationOutcome<Void> {
        if let ingredientReview = review as? TagMergeReview<Ingredient> {
            return try TagOperations.mergeDuplicatesWithOutcome(
                context: context,
                reviewed: ingredientReview
            )
        }

        if let categoryReview = review as? TagMergeReview<Category> {
            return try TagOperations.mergeDuplicatesWithOutcome(
                context: context,
                reviewed: categoryReview
            )
        }

        throw CookleActionError.unsupportedTagType(
            String(describing: T.self)
        )
    }

    func run<Value>(
        name: String,
        context: ModelContext,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        try await CookleMutationWorkflow.run(
            name: name,
            context: context,
            adapter: effectAdapter,
            operation: operation
        )
    }
}
