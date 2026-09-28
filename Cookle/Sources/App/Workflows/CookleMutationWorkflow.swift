import Foundation
import MHPlatform
import SwiftData

@MainActor
enum CookleMutationWorkflow {
    enum MutationError: LocalizedError {
        case pendingChanges

        var errorDescription: String? {
            String(localized: "Other changes are still waiting to be saved. Finish that edit and try again.")
        }
    }

    @MainActor
    private final class OutcomeBox<Value> {
        private(set) var savedOutcome: MutationOutcome<Value>?

        func store(_ outcome: MutationOutcome<Value>) {
            savedOutcome = outcome
        }

        func resolvedOutcome() -> MutationOutcome<Value> {
            guard let savedOutcome else {
                preconditionFailure("Mutation workflow completed without an outcome.")
            }
            return savedOutcome
        }

        nonisolated deinit {
            // Avoid the Swift 6.3 optimizer crash in synthesized generic deinitializers.
            // https://github.com/swiftlang/swift/issues/87462
        }
    }

    /// A workflow owns only changes it starts; never save or roll back another edit.
    static func requireCleanContext(_ context: ModelContext?) throws {
        guard context?.hasChanges != true else {
            throw MutationError.pendingChanges
        }
    }

    static func run<Value>(
        name: String,
        context: ModelContext?,
        adapter: MHMutationAdapter<MutationEffect>,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let outcomeBox = OutcomeBox<Value>()
        do {
            _ = try await MHMutationWorkflow.runThrowing(
                name: name,
                operation: {
                    try requireCleanContext(context)
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
                projection: .identity,
                operationErrorDescription: CookleLibraryErrorCopy.description
            )
        } catch {
            // Once the save commits, the change is done. Follow-up effects can
            // still be cancelled or fail, but reporting that as a failed save
            // would invite a retry that writes the change a second time.
            guard let savedOutcome = outcomeBox.savedOutcome else {
                throw error
            }
            return savedOutcome
        }
        return outcomeBox.resolvedOutcome()
    }
}
