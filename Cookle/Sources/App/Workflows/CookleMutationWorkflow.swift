import Foundation
import MHPlatform
import SwiftData

@MainActor
enum CookleMutationWorkflow {
    enum MutationError: LocalizedError {
        case pendingChanges
        case updateRequired

        var errorDescription: String? {
            switch self {
            case .pendingChanges:
                String(localized: "Other changes are still waiting to be saved. Finish that edit and try again.")
            case .updateRequired:
                String(localized: "Update Cookle to continue making changes. You can still view and export your data.")
            }
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

    static func performMutation<Value>(
        updates: RemoteUpdateOperations,
        operation: () throws -> Value
    ) async throws -> Value {
        do {
            return try await updates.performMutation(operation)
        } catch MHRemoteUpdateOperationError.updateRequired {
            throw MutationError.updateRequired
        }
    }

    static func run<Value>(
        name: String,
        context: ModelContext?,
        updates: RemoteUpdateOperations,
        adapter: MHMutationAdapter<MutationEffect>,
        operation: @escaping @MainActor () throws -> MutationOutcome<Value>
    ) async throws -> MutationOutcome<Value> {
        let outcomeBox = OutcomeBox<Value>()
        let cancellationHandle = MHCancellationHandle()
        let mutation = MHMutation<MutationEffect>.mainActor(name: name) {
            do {
                return try await performMutation(updates: updates) {
                    guard cancellationHandle.isCancelled == false else {
                        throw CancellationError()
                    }
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
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw OperationFailure(description: CookleLibraryErrorCopy.description(for: error))
            }
        }
        // The async main-actor mutation keeps the update check inside the operation,
        // immediately before the synchronous save. The workflow convenience accepts sync work only.
        let result = await withTaskCancellationHandler {
            await MHMutationRunner.run(mutation: mutation, adapter: adapter, cancellationHandle: cancellationHandle)
        } onCancel: {
            cancellationHandle.cancel()
        }
        // A committed write remains successful even if a follow-up fails or is cancelled;
        // reporting failure here would invite a retry that writes the change twice.
        if let savedOutcome = outcomeBox.savedOutcome {
            return savedOutcome
        }
        try throwFailure(result)
        return outcomeBox.resolvedOutcome()
    }
}

private extension CookleMutationWorkflow {
    struct OperationFailure: Error, CustomStringConvertible {
        let description: String
    }

    static func throwFailure(_ result: MHMutationOutcome<MutationEffect>) throws {
        switch result {
        case .succeeded:
            return
        case .failed(let failure, _, _, _):
            switch failure {
            case .operation(let description):
                throw MHMutationWorkflowError.operation(description)
            case let .step(name, description):
                throw MHMutationWorkflowError.step(name: name, description: description)
            }
        case .cancelled:
            throw CancellationError()
        }
    }
}
