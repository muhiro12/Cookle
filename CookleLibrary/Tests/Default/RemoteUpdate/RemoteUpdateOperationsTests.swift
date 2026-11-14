import CookleLibrary
import Foundation
import MHPlatformCore
import Synchronization
import Testing

@MainActor
struct RemoteUpdateOperationsTests {
    @Test
    func initialSharedConfigurationAllowsEditing() async throws {
        let fixture = try RemoteUpdateFixture(configuration: """
        {
          "schemaVersion": 1,
          "bundleIdentifier": "com.muhiro12.Cookle",
          "features": {
            "remoteUpdate": {
              "schemaVersion": 1,
              "revision": 1,
              "requirement": null,
              "scheduledRequirements": []
            }
          }
        }
        """)
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        try await updates.prepare()

        #expect(try await updates.performMutation { "saved" } == "saved")
        #expect(updates.decision == .notRequired)
        #expect(updates.evaluation?.revision == 1)
    }

    @Test(arguments: [false, true])
    func missingEvidenceAllowsOfflineEditingWithoutNetworking(preparesFirst: Bool) async throws {
        let fixture = try RemoteUpdateFixture()
        fixture.failsRefresh.withLock { $0 = true }
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        if preparesFirst {
            try await updates.prepare()
        }
        let fetchCount = fixture.fetchCount.withLock { $0 }

        #expect(try await updates.performMutation { "saved" } == "saved")
        #expect(updates.decision == .unavailable)
        #expect(fixture.fetchCount.withLock { $0 } == fetchCount)
        let preparation = try await updates.prepare()
        #expect(preparation?.refreshError != nil)
        #expect(try await updates.performMutation { "saved offline" } == "saved offline")
    }

    @Test(arguments: [false, true])
    func confirmedUpdateBlocksBothEntryPointsBeforeWriting(preparesFirst: Bool) async throws {
        let fixture = try RemoteUpdateFixture()
        let controller = try fixture.controller()
        try await controller.prepare()
        let updates = RemoteUpdateOperations(controller: controller)
        if preparesFirst {
            try await updates.prepare()
        }
        var didWrite = false
        var didRunSuccessEffect = false

        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await updates.performMutation {
                didWrite = true
            }
            didRunSuccessEffect = true
        }
        #expect(didWrite == false)
        #expect(didRunSuccessEffect == false)
        #expect(updates.decision == .updateRequired)
    }

    @Test
    func firstHeadlessMutationRestoresRequiredUpdateWithoutNetworking() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MHRemoteUpdateStore(fileURL: directory.appendingPathComponent("snapshot.json"))
        let fixture = try RemoteUpdateFixture()
        let first = RemoteUpdateOperations(controller: try fixture.controller(store: store))
        try await first.prepare()
        let fetchCount = fixture.fetchCount.withLock { $0 }
        fixture.failsRefresh.withLock { $0 = true }
        let headless = RemoteUpdateOperations(controller: try fixture.controller(store: store))
        var didWrite = false

        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await headless.performMutation { didWrite = true }
        }
        #expect(didWrite == false)
        #expect(headless.evaluation?.revision == 1)
        #expect(fixture.fetchCount.withLock { $0 } == fetchCount)
    }

    @Test
    func retainedPlanActivatesAtMutationTimeWithoutForegroundRefresh() async throws {
        let fixture = try RemoteUpdateFixture(effectiveAt: 1_100)
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        try await updates.prepare()
        #expect(try await updates.performMutation { "before activation" } == "before activation")
        fixture.clock.withLock { $0 = Date(timeIntervalSinceReferenceDate: 1_100) }

        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await updates.performMutation { Issue.record("The active plan must block this write.") }
        }
        #expect(updates.decision == .updateRequired)
        #expect(fixture.fetchCount.withLock { $0 } == 1)
    }

    @Test
    func refreshFailurePreservesConfirmedRestriction() async throws {
        let fixture = try RemoteUpdateFixture()
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        try await updates.prepare()
        fixture.failsRefresh.withLock { $0 = true }
        let preparation = try await updates.prepare()

        #expect(preparation?.refreshError != nil)
        await #expect(throws: MHRemoteUpdateOperationError.updateRequired) {
            try await updates.performMutation { Issue.record("Failed refresh must retain valid evidence.") }
        }
    }

    @Test
    func expiredPublicationAllowsOfflineEditingWithoutRenewingEvidence() async throws {
        let fixture = try RemoteUpdateFixture()
        let updates = RemoteUpdateOperations(controller: try fixture.controller())
        try await updates.prepare()
        let originalPublication = updates.evaluation?.publication
        fixture.clock.withLock { $0 = Date(timeIntervalSinceReferenceDate: 1_600) }

        #expect(try await updates.performMutation { "offline save" } == "offline save")
        #expect(updates.decision == .unavailable)
        #expect(updates.evaluation?.publication == originalPublication)
        #expect(fixture.fetchCount.withLock { $0 } == 1)
    }

    @Test(arguments: [false, true])
    func cancellationNeverRunsTheWriteEvenWhenEvidenceIsUnavailable(isIsolated: Bool) async throws {
        let fixture = try RemoteUpdateFixture()
        let updates = if isIsolated {
            RemoteUpdateOperations()
        } else {
            RemoteUpdateOperations(controller: try fixture.controller())
        }
        var didWrite = false
        var didRunSuccessEffect = false
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await updates.performMutation { didWrite = true }
            didRunSuccessEffect = true
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(didWrite == false)
        #expect(didRunSuccessEffect == false)
        #expect(fixture.fetchCount.withLock { $0 } == 0)
    }

    @Test
    func isolatedEnvironmentDoesNotEnforceOrRefresh() async throws {
        let updates = RemoteUpdateOperations()

        #expect(try await updates.prepare() == nil)
        #expect(try await updates.performMutation { "preview save" } == "preview save")
        #expect(updates.evaluation == nil)
    }
}
