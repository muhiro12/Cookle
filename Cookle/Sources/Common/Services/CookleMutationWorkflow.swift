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

    private enum ExecutionError: LocalizedError, Sendable, CustomStringConvertible {
        case operation(String)
        case step(name: String, description: String)

        var description: String {
            switch self {
            case .operation(let description):
                return description
            case let .step(name, description):
                if description.isEmpty {
                    return "Mutation step \(name) failed."
                }
                return description
            }
        }

        var errorDescription: String? {
            description
        }
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
        let mutation = MHMutation.mainActor(name: name) {
            do {
                return try operation()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ExecutionError.operation(error.localizedDescription)
            }
        }

        let outcome = await MHMutationRunner.run(
            mutation: mutation,
            adapter: adapter
        )

        switch outcome {
        case .succeeded(let effects, _, _):
            return effects
        case .failed(let failure, _, _, _):
            switch failure {
            case .operation(let description):
                throw ExecutionError.operation(description)
            case let .step(name, description):
                throw ExecutionError.step(
                    name: name,
                    description: description
                )
            }
        case .cancelled:
            throw CancellationError()
        }
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
