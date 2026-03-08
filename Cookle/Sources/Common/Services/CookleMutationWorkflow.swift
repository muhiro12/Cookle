import Foundation
import MHPlatform

enum CookleMutationWorkflow {
    typealias NotificationSynchronizer = @MainActor @Sendable () async -> Void
    typealias ReviewRequester = @MainActor @Sendable () async -> MHReviewRequestOutcome
    typealias WidgetReloader = @MainActor @Sendable () -> Void

    nonisolated static func effectAdapter(
        reloadRecipeWidgets: @escaping WidgetReloader = {
            CookleWidgetReloader.reloadRecipeWidgets()
        },
        reloadDiaryWidgets: @escaping WidgetReloader = {
            CookleWidgetReloader.reloadTodayDiaryWidget()
        },
        synchronizeNotifications: @escaping NotificationSynchronizer = {
            // no-op
        },
        requestReviewIfNeeded: ReviewRequester? = nil
    ) -> MHMutationAdapter<MutationEffect> {
        .init { effects in
            mutationSteps(
                for: effects,
                reloadRecipeWidgets: reloadRecipeWidgets,
                reloadDiaryWidgets: reloadDiaryWidgets,
                synchronizeNotifications: synchronizeNotifications,
                requestReviewIfNeeded: requestReviewIfNeeded
            )
        }
    }

    static func run(
        name: String,
        operation: @escaping @MainActor @Sendable () -> MutationEffect,
        adapter: MHMutationAdapter<MutationEffect>
    ) async -> MutationEffect {
        do {
            return try await runThrowing(
                name: name,
                operation: {
                    operation()
                },
                adapter: adapter
            )
        } catch {
            assertionFailure(error.localizedDescription)
            return []
        }
    }

    static func runThrowing(
        name: String,
        operation: @escaping @MainActor @Sendable () throws -> MutationEffect,
        adapter: MHMutationAdapter<MutationEffect>
    ) async throws -> MutationEffect {
        try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: operation,
            adapter: adapter
        )
    }

    static func run<Value: Sendable>(
        name: String,
        operation: @escaping @MainActor @Sendable () -> Value,
        adapter: MHMutationAdapter<MutationEffect>,
        afterSuccess: @escaping @MainActor @Sendable (Value) -> MutationEffect
    ) async -> MutationOutcome<Value> {
        do {
            return try await runThrowing(
                name: name,
                operation: {
                    operation()
                },
                adapter: adapter,
                afterSuccess: afterSuccess
            )
        } catch {
            assertionFailure(error.localizedDescription)
            preconditionFailure("Mutation unexpectedly failed: \(name)")
        }
    }

    static func runThrowing<Value: Sendable>(
        name: String,
        operation: @escaping @MainActor @Sendable () throws -> Value,
        adapter: MHMutationAdapter<MutationEffect>,
        afterSuccess: @escaping @MainActor @Sendable (Value) -> MutationEffect
    ) async throws -> MutationOutcome<Value> {
        let value = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: operation,
            adapter: adapter,
            afterSuccess: afterSuccess
        ) { $0 }
        return .init(
            value: value,
            effects: afterSuccess(value)
        )
    }

    nonisolated private static func mutationSteps(
        for effects: MutationEffect,
        reloadRecipeWidgets: @escaping WidgetReloader,
        reloadDiaryWidgets: @escaping WidgetReloader,
        synchronizeNotifications: @escaping NotificationSynchronizer,
        requestReviewIfNeeded: ReviewRequester?
    ) -> [MHMutationStep] {
        var steps = [MHMutationStep]()

        if effects.contains(.recipeDataChanged) {
            steps.append(
                .mainActor(
                    name: "reloadRecipeWidgets",
                    action: reloadRecipeWidgets
                )
            )
        }

        if effects.contains(.diaryDataChanged) {
            steps.append(
                .mainActor(
                    name: "reloadDiaryWidgets",
                    action: reloadDiaryWidgets
                )
            )
        }

        if effects.contains(.notificationPlanChanged) {
            steps.append(
                .mainActor(name: "synchronizeNotifications") {
                    await synchronizeNotifications()
                }
            )
        }

        if effects.contains(.reviewPromptEligible),
           let requestReviewIfNeeded {
            steps.append(
                .mainActor(name: "requestReviewIfNeeded") {
                    _ = await requestReviewIfNeeded()
                }
            )
        }

        return steps
    }
}
