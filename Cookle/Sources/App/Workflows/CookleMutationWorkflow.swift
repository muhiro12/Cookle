import MHPlatform
import SwiftData

@MainActor
enum CookleMutationWorkflow {
    // Domain values stay on the main actor; this carrier only satisfies the workflow result boundary.
    private struct OperationResult<Value>: @unchecked Sendable {
        let outcome: MutationOutcome<Value>
        let effects: MutationEffect
    }

    static func run<Value>(
        name: String,
        context: ModelContext?,
        adapter: MHMutationAdapter<MutationEffect>,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let result = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                do {
                    let outcome = try operation()
                    try context?.save()
                    return OperationResult(
                        outcome: outcome,
                        effects: outcome.effects
                    )
                } catch {
                    context?.rollback()
                    throw error
                }
            },
            adapter: adapter,
            projection: .valueAndFollowUp(
                value: \.self,
                followUp: \.effects
            )
        )
        return result.outcome
    }
}
