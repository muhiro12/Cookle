import Foundation
import MHPlatformCore
import Observation

/// Shares update evidence between presentation and user-data mutation adapters.
@preconcurrency
@MainActor
@Observable
public final class RemoteUpdateOperations {
    /// The latest diagnostic snapshot; reading it does not renew retained evidence.
    public private(set) var evaluation: MHRemoteUpdateEvaluation?

    /// The decision from the latest observed instant, rather than permission for a later write.
    public var decision: MHRemoteUpdateDecision {
        evaluation?.decision ?? .unavailable
    }

    private let controller: MHRemoteUpdateController?

    /// Disables networking and enforcement for previews and isolated environments.
    public init() {
        controller = nil
    }

    /// Uses one package-owned controller for this app environment.
    public init(controller: MHRemoteUpdateController) {
        self.controller = controller
    }

    /// Restores and refreshes evidence at startup and foreground transitions.
    @discardableResult
    public func prepare() async throws -> MHRemoteUpdateController.Preparation? {
        try Task.checkCancellation()
        guard let controller else {
            return nil
        }
        let preparation = try await controller.prepare()
        try Task.checkCancellation()
        evaluation = preparation.evaluation
        return preparation
    }

    /// Keeps offline editing available while always rejecting a confirmed required update.
    public func checkMutationAllowed() async throws {
        try Task.checkCancellation()
        guard let controller else {
            return
        }
        do {
            try await controller.checkOperationAllowed(for: .allowWhenUnavailable)
            evaluation = await controller.evaluation()
            try Task.checkCancellation()
            try decision.checkOperationAllowed(whenUnavailable: .allow)
        } catch {
            evaluation = await controller.evaluation()
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }
            throw error
        }
    }

    /// Checks immediately before a synchronous write, with no intervening suspension.
    public func performMutation<Value>(
        _ operation: () throws -> Value
    ) async throws -> Value {
        try await checkMutationAllowed()
        try Task.checkCancellation()
        return try operation()
    }
}
