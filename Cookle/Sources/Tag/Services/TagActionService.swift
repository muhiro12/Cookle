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
        let effects = tagMutationEffects
        let _: Void = try await MHMutationWorkflow.runThrowing(
            name: "renameIngredient",
            operation: {
                try TagService.rename(
                    context: context,
                    ingredient: ingredient,
                    value: value
                )
            },
            adapter: effectAdapter,
            adapterValue: effects
        )
        return .init(
            value: (),
            effects: effects
        )
    }

    @discardableResult
    func rename(
        context: ModelContext,
        category: Category,
        value: String
    ) async throws -> MutationOutcome<Void> {
        let effects = tagMutationEffects
        let _: Void = try await MHMutationWorkflow.runThrowing(
            name: "renameCategory",
            operation: {
                try TagService.rename(
                    context: context,
                    category: category,
                    value: value
                )
            },
            adapter: effectAdapter,
            adapterValue: effects
        )
        return .init(
            value: (),
            effects: effects
        )
    }

    @discardableResult
    func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) async throws -> MutationOutcome<Void> {
        let effects = tagMutationEffects
        let _: Void = try await MHMutationWorkflow.runThrowing(
            name: "deleteIngredient",
            operation: {
                try TagService.delete(
                    context: context,
                    ingredient: ingredient
                )
            },
            adapter: effectAdapter,
            adapterValue: effects
        )
        return .init(
            value: (),
            effects: effects
        )
    }

    @discardableResult
    func delete(
        context: ModelContext,
        category: Category
    ) async throws -> MutationOutcome<Void> {
        let effects = tagMutationEffects
        let _: Void = try await MHMutationWorkflow.runThrowing(
            name: "deleteCategory",
            operation: {
                TagService.delete(
                    context: context,
                    category: category
                )
            },
            adapter: effectAdapter,
            adapterValue: effects
        )
        return .init(
            value: (),
            effects: effects
        )
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
    var tagMutationEffects: MutationEffect {
        [
            .notificationPlanChanged
        ]
    }
}
