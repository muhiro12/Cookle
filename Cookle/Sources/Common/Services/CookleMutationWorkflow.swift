import Foundation
import MHPlatform

@MainActor
enum CookleMutationWorkflow {
    typealias NotificationSynchronizer = @MainActor @Sendable () async -> Void
    typealias ReviewRequester = @MainActor @Sendable () async -> MHReviewRequestOutcome
    typealias WidgetReloader = @MainActor @Sendable () -> Void

    final class ValueStore<Value> {
        var value: Value?
    }

    static func effectAdapter(
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

    private static func mutationSteps(
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
