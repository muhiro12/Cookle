import Foundation
import MHPlatformCore
import Observation

/// Shares update evidence between presentation and user-data mutation adapters.
@preconcurrency
@MainActor
@Observable
public final class RemoteUpdateOperations {
    /// The latest diagnostic snapshot; reading it does not renew retained evidence.
    public var evaluation: MHRemoteUpdateEvaluation? {
        adapter.evaluation
    }

    /// The decision from the latest observed instant, rather than permission for a later write.
    public var decision: MHRemoteUpdateDecision {
        evaluation?.decision ?? .unavailable
    }

    private let adapter: MHRemoteUpdateAdapter

    /// Disables networking and enforcement for previews and isolated environments.
    public init() {
        adapter = .preview()
    }

    /// Uses one package-owned controller for this app environment.
    public init(controller: MHRemoteUpdateController) {
        adapter = .init(controller: controller)
    }

    /// Restores and refreshes evidence at startup and foreground transitions.
    @discardableResult
    public func prepare() async throws -> MHRemoteUpdateController.Preparation? {
        try await adapter.prepare()
    }

    /// Keeps offline editing available while always rejecting a confirmed required update.
    /// This check does not reserve permission; use `performMutation` for the actual write.
    public func checkMutationAllowed() async throws {
        try await adapter.perform(policy: .allowWhenUnavailable) {
            ()
        }
    }

    /// Checks immediately before a synchronous write, with no intervening suspension.
    public func performMutation<Value>(
        _ operation: () throws -> Value
    ) async throws -> Value {
        try await adapter.perform(policy: .allowWhenUnavailable, operation)
    }
}
