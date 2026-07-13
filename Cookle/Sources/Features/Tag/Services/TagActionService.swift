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

    @discardableResult
    func delete(
        context: ModelContext,
        category: Category
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteCategory",
            context: context
        ) {
            TagOperations.deleteWithOutcome(
                context: context,
                category: category
            )
        }
    }

    @discardableResult
    func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteIngredient",
            context: context
        ) {
            try TagOperations.deleteWithOutcome(
                context: context,
                ingredient: ingredient
            )
        }
    }

    @discardableResult
    func mergeDuplicates<T: Tag>(
        context: ModelContext,
        keeping tag: T
    ) async throws -> MutationOutcome<Void> {
        if let ingredient = tag as? Ingredient {
            return try await run(
                name: "mergeDuplicateIngredients",
                context: context
            ) {
                try TagOperations.mergeDuplicatesWithOutcome(
                    context: context,
                    keeping: ingredient
                )
            }
        }

        if let category = tag as? Category {
            return try await run(
                name: "mergeDuplicateCategories",
                context: context
            ) {
                try TagOperations.mergeDuplicatesWithOutcome(
                    context: context,
                    keeping: category
                )
            }
        }

        throw CookleActionError.unsupportedTagType(
            String(describing: T.self)
        )
    }
}

private extension TagActionService {
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
