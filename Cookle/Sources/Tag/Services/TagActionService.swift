import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class TagActionService {
    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init(notificationService: NotificationService) {
        let synchronizeNotifications: CookleMutationWorkflow.NotificationSynchronizer = {
            await notificationService.synchronizeScheduledSuggestions()
        }
        effectAdapter = CookleMutationWorkflow.effectAdapter(
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
            name: "renameIngredient"
        ) {
            try TagService.rename(
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
            name: "renameCategory"
        ) {
            try TagService.rename(
                context: context,
                category: category,
                value: value
            )
        }
    }

    @discardableResult
    func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteIngredient"
        ) {
            try TagService.delete(
                context: context,
                ingredient: ingredient
            )
        }
    }

    @discardableResult
    func delete(
        context: ModelContext,
        category: Category
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deleteCategory"
        ) {
            TagService.delete(
                context: context,
                category: category
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

        preconditionFailure("Unsupported tag type: \(T.self)")
    }

    @discardableResult
    func delete<T: Tag>(
        context: ModelContext,
        tag: T
    ) async throws -> MutationOutcome<Void> {
        if let ingredient = tag as? Ingredient {
            return try await delete(
                context: context,
                ingredient: ingredient
            )
        }

        if let category = tag as? Category {
            return try await delete(
                context: context,
                category: category
            )
        }

        preconditionFailure("Unsupported tag type: \(T.self)")
    }
}

private extension TagActionService {
    func run(
        name: String,
        operation: @escaping @MainActor @Sendable () throws -> Void
    ) async throws -> MutationOutcome<Void> {
        try await CookleMutationWorkflow.runThrowing(
            name: name,
            operation: operation,
            adapter: effectAdapter,
            afterSuccess: tagMutationEffects(for:)
        )
    }

    func tagMutationEffects(
        for _: Void
    ) -> MutationEffect {
        [
            .notificationPlanChanged
        ]
    }
}
