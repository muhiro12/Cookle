import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class PhotoActionService {
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
            name: "deletePhoto",
            context: context
        ) {
            PhotoOperations.deleteWithOutcome(
                context: context,
                photo: photo
            )
        }
    }
}

private extension PhotoActionService {
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
