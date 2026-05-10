import MHPlatform

@MainActor
enum CookleMutationWorkflow {
    // Domain values stay on the main actor; this carrier only satisfies the workflow result boundary.
    private struct OperationResult<Value>: @unchecked Sendable {
        let outcome: MutationOutcome<Value>
        let effects: MutationEffect
    }

    static func run<Value>(
        name: String,
        adapter: MHMutationAdapter<MutationEffect>,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let result = try await MHMutationWorkflow.runThrowing(
            name: name,
            operation: {
                let outcome = try operation()
                return OperationResult(
                    outcome: outcome,
                    effects: outcome.effects
                )
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
