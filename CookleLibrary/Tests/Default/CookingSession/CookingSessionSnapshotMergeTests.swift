@testable import CookleLibrary
import Foundation
import Testing

struct CookingSessionSnapshotMergeTests {
    @Test
    func merging_prefers_newer_snapshot_and_ignores_stale_payload() {
        let currentSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 300),
            isActive: true
        )
        let staleSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-2",
            recipeName: "Soup",
            steps: ["Simmer"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 200),
            isActive: true
        )
        let freshSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-2",
            recipeName: "Soup",
            steps: ["Simmer"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 400),
            isActive: true
        )

        #expect(currentSnapshot.merging(with: staleSnapshot) == currentSnapshot)
        #expect(currentSnapshot.merging(with: freshSnapshot) == freshSnapshot)
    }

    @Test
    func decoded_accepts_a_payload_without_an_active_timer() {
        let payloadWithoutTimer = """
        {"currentStepIndex":0,"isActive":true,"recipeID":"recipe-1",\
        "recipeName":"Pasta","steps":["Boil water"],"updatedAt":300}
        """.replacingOccurrences(of: "\\\n", with: "")

        let decodedSnapshot = CookingSessionSnapshot.decoded(from: payloadWithoutTimer)

        // `activeTimer` is decoded with `decodeIfPresent`, so payloads written
        // before a timer existed still load rather than being treated as corrupt.
        #expect(decodedSnapshot?.recipeID == "recipe-1")
        #expect(decodedSnapshot?.activeTimer == nil)
    }

    @Test
    func decoded_ignores_unknown_keys_so_newer_payloads_still_load() {
        let payloadWithUnknownKey = """
        {"currentStepIndex":0,"isActive":true,"recipeID":"recipe-1",\
        "recipeName":"Pasta","steps":["Boil water"],"updatedAt":300,\
        "unknownFutureField":"ignored"}
        """.replacingOccurrences(of: "\\\n", with: "")

        let decodedSnapshot = CookingSessionSnapshot.decoded(from: payloadWithUnknownKey)

        // Additive wire changes stay readable by an older peer.
        #expect(decodedSnapshot?.recipeID == "recipe-1")
    }

    @Test
    func decoded_returns_nil_for_malformed_and_incomplete_payloads() {
        // Malformed and merely-unsupported payloads are indistinguishable at this
        // layer; only "no snapshot at all" is separable, and its owner is the store.
        #expect(CookingSessionSnapshot.decoded(from: "not json") == nil)
        #expect(CookingSessionSnapshot.decoded(from: "{}") == nil)

        let payloadMissingIsActive = """
        {"currentStepIndex":0,"recipeID":"recipe-1","recipeName":"Pasta",\
        "steps":["Boil water"],"updatedAt":300}
        """.replacingOccurrences(of: "\\\n", with: "")

        #expect(CookingSessionSnapshot.decoded(from: payloadMissingIsActive) == nil)
    }

    // The following cases record how `merging(with:)` behaves today for the
    // conflict situations #134 lists. They are characterization tests: they pin
    // current last-writer-wins behavior so that any change to the merge rules or
    // the wire contract has to be a deliberate edit, not a silent regression.

    @Test
    func merging_keeps_the_local_snapshot_when_timestamps_tie() {
        let sharedDate = Date(timeIntervalSinceReferenceDate: 300)
        let localSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: nil,
            updatedAt: sharedDate,
            isActive: true
        )
        let incomingSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: sharedDate,
            isActive: true
        )

        // A tie resolves in favor of the receiver, so each device keeps its own
        // state and the two do not converge until a later update breaks the tie.
        #expect(localSnapshot.merging(with: incomingSnapshot) == localSnapshot)
        #expect(incomingSnapshot.merging(with: localSnapshot) == incomingSnapshot)
    }

    @Test
    func merging_lets_a_skewed_clock_overwrite_newer_progress() {
        let localSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 300),
            isActive: true
        )
        // Produced earlier in real time, but stamped by a device whose clock runs ahead.
        let skewedSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 3_600),
            isActive: true
        )

        // Timestamps are compared directly, so clock skew alone can roll progress back.
        #expect(localSnapshot.merging(with: skewedSnapshot) == skewedSnapshot)
        #expect(localSnapshot.merging(with: skewedSnapshot).currentStepIndex == 0)
    }

    @Test
    func merging_revives_an_ended_session_when_a_later_active_snapshot_arrives() {
        let endedSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 300),
            isActive: true
        )
        .endingSession(updatedAt: Date(timeIntervalSinceReferenceDate: 400))

        // A peer that had not yet seen the end still reports an active session.
        let replayedActiveSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: .init(
                durationSeconds: 600,
                startedAt: Date(timeIntervalSinceReferenceDate: 500)
            ),
            updatedAt: Date(timeIntervalSinceReferenceDate: 500),
            isActive: true
        )

        #expect(endedSnapshot.isActive == false)
        // `isActive` carries no authority over `updatedAt`, so the ended session
        // comes back and its timer restarts. #134 owns the decision to change this.
        #expect(endedSnapshot.merging(with: replayedActiveSnapshot).isActive)
        #expect(endedSnapshot.merging(with: replayedActiveSnapshot).activeTimer != nil)
    }

    @Test
    func merging_ignores_an_ended_snapshot_that_is_older_than_local_progress() {
        let activeSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 500),
            isActive: true
        )
        let staleEndedSnapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 400),
            isActive: false
        )

        // A late-arriving end for an older state does not cancel newer local cooking.
        #expect(activeSnapshot.merging(with: staleEndedSnapshot) == activeSnapshot)
    }

    @Test
    func merging_replaces_a_concurrent_session_for_a_different_recipe() {
        let phoneSession = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water", "Cook pasta"],
            currentStepIndex: 1,
            activeTimer: .init(
                durationSeconds: 600,
                startedAt: Date(timeIntervalSinceReferenceDate: 300)
            ),
            updatedAt: Date(timeIntervalSinceReferenceDate: 300),
            isActive: true
        )
        let watchSession = CookingSessionSnapshot(
            recipeID: "recipe-2",
            recipeName: "Soup",
            steps: ["Simmer"],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 400),
            isActive: true
        )

        let merged = phoneSession.merging(with: watchSession)

        // There is no session identity in the contract, so an independently started
        // session on the other device replaces the running one, timer included.
        #expect(merged == watchSession)
        #expect(merged.recipeID == "recipe-2")
        #expect(merged.activeTimer == nil)
    }
}
