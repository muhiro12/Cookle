import CookleLibrary
import Foundation
import MHPlatformCore
import Observation
import Synchronization
import Testing

@MainActor
struct RemoteUpdateAdapterAdoptionTests {
    private enum MutationFailure: Error {
        case rejected
    }

    @Test
    func preparationFailureReportsNetworkErrorAndStillAllowsOfflineEditing() async throws {
        let fixture = try RemoteUpdateFixture()
        fixture.failsRefresh.withLock { $0 = true }
        let updates = RemoteUpdateOperations(controller: try fixture.controller())

        let preparation = try await updates.prepare()
        #expect((preparation?.refreshError as? URLError)?.code == .notConnectedToInternet)
        #expect(updates.evaluation?.refreshError != nil)
        try await updates.checkMutationAllowed()
        #expect(try await updates.performMutation { "saved" } == "saved")
        #expect(fixture.fetchCount.withLock { $0 } == 1)
    }

    @Test
    func cancellationDuringPreparationPreventsWriteAndSuccessEffect() async throws {
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        defer {
            started.continuation.finish()
            release.continuation.finish()
        }
        let fixture = try RemoteUpdateFixture()
        let controller = try fixture.controller {
            started.continuation.yield(())
            for await _ in release.stream {
                break
            }
            try Task.checkCancellation()
        }
        let updates = RemoteUpdateOperations(controller: controller)
        var didWrite = false
        var didRunSuccessEffect = false
        let task = Task { @MainActor in
            try await updates.prepare()
            try await updates.performMutation { didWrite = true }
            didRunSuccessEffect = true
        }
        var iterator = started.stream.makeAsyncIterator()
        await iterator.next()
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(didWrite == false)
        #expect(didRunSuccessEffect == false)
        #expect(updates.decision == .unavailable)
    }

    @Test
    func permissionCheckDoesNotAuthorizeALaterWrite() async throws {
        let fixture = try RemoteUpdateFixture(effectiveAt: 1_100)
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        try await updates.prepare()
        try await updates.checkMutationAllowed()
        fixture.clock.withLock { $0 = Date(timeIntervalSinceReferenceDate: 1_100) }
        #expect(updates.decision == .notRequired)

        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await updates.performMutation {
                Issue.record("A prior permission check must not authorize this write.")
            }
        }
        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await updates.checkMutationAllowed()
        }
        #expect(fixture.fetchCount.withLock { $0 } == 1)
    }

    @Test
    func observationFollowsTheSharedAdapterEvaluation() async throws {
        let fixture = try RemoteUpdateFixture()
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        let didChange = Mutex(false)
        withObservationTracking {
            #expect(updates.decision == .unavailable)
        } onChange: {
            didChange.withLock { $0 = true }
        }

        try await updates.prepare()

        #expect(didChange.withLock { $0 })
        #expect(updates.decision == .updateRequired)
        #expect(updates.evaluation?.revision == 1)
    }

    @Test(arguments: [false, true])
    func mutationErrorsPropagateWithoutSuccessEffects(isIsolated: Bool) async throws {
        let fixture = try RemoteUpdateFixture()
        let updates = if isIsolated {
            RemoteUpdateOperations()
        } else {
            RemoteUpdateOperations(controller: try fixture.controller())
        }
        var didRunSuccessEffect = false

        await #expect(throws: MutationFailure.rejected) {
            try await updates.performMutation {
                throw MutationFailure.rejected
            }
            didRunSuccessEffect = true
        }
        #expect(didRunSuccessEffect == false)
        #expect(fixture.fetchCount.withLock { $0 } == 0)
    }
}
