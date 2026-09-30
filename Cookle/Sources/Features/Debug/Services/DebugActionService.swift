import SwiftData

@MainActor
enum DebugActionService {
    /// Commits the selected inspector deletions together through the app workflow.
    static func delete<Model: PersistentModel>(
        context: ModelContext,
        models: [Model],
        notificationService: NotificationService
    ) async throws {
        let adapter = CookleMutationEffectAdapter.make(
            synchronizeNotifications: {
                await notificationService.synchronizeScheduledSuggestions()
            },
            reviewFlow: nil
        )
        _ = try await CookleMutationWorkflow.run(
            name: "deleteDiagnosticRecords",
            context: context,
            adapter: adapter
        ) {
            var effects = MutationEffect()
            for model in models {
                let outcome = try DiagnosticOperations.deleteWithOutcome(
                    context: context,
                    model: model
                )
                effects.formUnion(outcome.effects)
            }
            return MutationOutcome(value: (), effects: effects)
        }
    }
}
