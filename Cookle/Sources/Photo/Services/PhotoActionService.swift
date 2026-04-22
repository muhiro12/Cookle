import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class PhotoActionService {
    private struct OperationResult<Value> {
        let value: Value
        let effects: MutationEffect
    }

    private let effectAdapter: MHMutationAdapter<MutationEffect>

    init(notificationService: NotificationService) {
        self.effectAdapter = CookleMutationEffectAdapter.make(
            synchronizeNotifications: {
                await notificationService.synchronizeScheduledSuggestions()
            },
            reviewFlow: nil
        )
    }

    @discardableResult
    func delete(
        context: ModelContext,
        photo: Photo
    ) async throws -> MutationOutcome<Void> {
        try await run(
            name: "deletePhoto"
        ) {
            PhotoService.deleteWithOutcome(
                context: context,
                photo: photo
            )
        }
    }
}

private extension PhotoActionService {
    func run<Value>(
        name: String,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let result = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                let outcome = try operation()
                return OperationResult(
                    value: outcome.value,
                    effects: outcome.effects
                )
            },
            adapter: effectAdapter,
            projection: .closures(
                afterSuccess: { result in
                    result.effects
                },
                returning: { result in
                    result
                }
            )
        )
        return .init(
            value: result.value,
            effects: result.effects
        )
    }
}
