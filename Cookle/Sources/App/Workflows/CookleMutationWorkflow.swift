import MHPlatform
import SwiftData

@MainActor
enum CookleMutationWorkflow {
    @MainActor
    private final class OutcomeBox<Value> {
        private var outcome: MutationOutcome<Value>?

        func store(_ outcome: MutationOutcome<Value>) {
            self.outcome = outcome
        }

        func resolvedOutcome() -> MutationOutcome<Value> {
            guard let outcome else {
                preconditionFailure("Mutation workflow completed without an outcome.")
            }
            return outcome
        }
    }

    static func run<Value>(
        name: String,
        context: ModelContext?,
        adapter: MHMutationAdapter<MutationEffect>,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let outcomeBox = OutcomeBox<Value>()
        _ = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                do {
                    let outcome = try operation()
                    try context?.save()
                    outcomeBox.store(outcome)
                    return outcome.effects
                } catch {
                    context?.rollback()
                    throw error
                }
            },
            adapter: adapter,
            projection: .identity
        )
        return outcomeBox.resolvedOutcome()
    }
}
