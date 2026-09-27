@testable import CookleLibrary
import Foundation
import Testing

struct CookingSessionLocalStateTests {
    private static func snapshot(
        recipeID: String = "recipe-1",
        stepIndex: Int = 0,
        at seconds: TimeInterval = 300
    ) -> CookingSessionSnapshot {
        .init(
            recipeID: recipeID,
            recipeName: recipeID,
            steps: ["One", "Two", "Three"],
            currentStepIndex: stepIndex,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: seconds),
            isActive: true
        )
    }

    @Test
    func end_dominates_a_delayed_active_revision_regardless_of_clocks() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        var watch = CookingSessionLocalState(originID: "watch")
        watch.merge(phone.shared)
        watch.updateActiveSession { $0.advancingToNextStep(updatedAt: .init(timeIntervalSinceReferenceDate: 9_999)) }
        let delayedActive = watch.shared

        phone.endActiveSession(updatedAt: Date(timeIntervalSinceReferenceDate: 1))
        phone.merge(delayedActive)

        #expect(phone.activeSnapshot == nil)
        watch.merge(phone.shared)
        #expect(watch.activeSnapshot == nil)
    }

    @Test
    func ended_session_never_revives_after_a_new_start_and_replay() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot(recipeID: "pasta"))
        let oldActive = phone.shared
        phone.endActiveSession()
        phone.start(Self.snapshot(recipeID: "soup"))

        var watch = CookingSessionLocalState(originID: "watch")
        watch.merge(phone.shared)
        watch.merge(oldActive)
        phone.merge(oldActive)

        #expect(phone.activeSnapshot?.recipeID == "soup")
        #expect(watch.activeSnapshot?.recipeID == "soup")
        #expect(phone.pendingConflict == nil)
        #expect(watch.pendingConflict == nil)
    }

    @Test
    func same_recipe_restart_is_a_new_session() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        let first = phone.activeRecord?.sessionID
        phone.endActiveSession()
        phone.start(Self.snapshot())

        #expect(phone.activeRecord?.sessionID != first)
        #expect(phone.activeRecord?.sessionID.sequence == 2)
    }

    @Test
    func same_session_edits_order_by_revision_not_timestamp() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        var watch = CookingSessionLocalState(originID: "watch")
        watch.merge(phone.shared)

        // Skewed clock on the older revision.
        let skewed = phone.shared
        watch.updateActiveSession { $0.settingCurrentStepIndex(2, updatedAt: .init(timeIntervalSinceReferenceDate: 1)) }
        var skewedPhone = phone
        skewedPhone.merge(watch.shared)
        watch.merge(skewed)

        #expect(watch.activeSnapshot?.currentStepIndex == 2)
        #expect(skewedPhone.activeSnapshot?.currentStepIndex == 2)
    }

    @Test
    func equal_revisions_break_ties_deterministically() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        var watch = CookingSessionLocalState(originID: "watch")
        watch.merge(phone.shared)

        phone.updateActiveSession { $0.settingCurrentStepIndex(1) }
        watch.updateActiveSession { $0.settingCurrentStepIndex(2) }
        let phoneShared = phone.shared
        phone.merge(watch.shared)
        watch.merge(phoneShared)

        #expect(phone.activeSnapshot == watch.activeSnapshot)
        #expect(phone.activeRecord?.editorID == "watch")
    }

    @Test
    func duplicate_and_out_of_order_delivery_converges_without_changes() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        let revision1 = phone.shared
        phone.updateActiveSession { $0.advancingToNextStep() }
        let revision2 = phone.shared

        var watch = CookingSessionLocalState(originID: "watch")
        let initialChange = watch.merge(revision2)
        let duplicateChange = watch.merge(revision2)
        let staleChange = watch.merge(revision1)
        #expect(initialChange)
        #expect(duplicateChange == false)
        #expect(staleChange == false)
        #expect(watch.activeSnapshot?.currentStepIndex == 1)
    }

    @Test
    func independent_starts_keep_local_session_and_offer_a_choice() {
        var phone = CookingSessionLocalState(originID: "phone")
        var watch = CookingSessionLocalState(originID: "watch")
        phone.start(Self.snapshot(recipeID: "pasta"))
        watch.start(Self.snapshot(recipeID: "soup"))
        let phoneShared = phone.shared

        phone.merge(watch.shared)
        watch.merge(phoneShared)

        #expect(phone.activeSnapshot?.recipeID == "pasta")
        #expect(phone.pendingConflict?.snapshot.recipeID == "soup")
        #expect(watch.activeSnapshot?.recipeID == "soup")
        #expect(watch.pendingConflict?.snapshot.recipeID == "pasta")

        phone.resolveConflict(keepingLocalSession: false)
        watch.merge(phone.shared)

        #expect(phone.activeSnapshot?.recipeID == "soup")
        #expect(watch.activeSnapshot?.recipeID == "soup")
        #expect(watch.pendingConflict == nil)
        phone.merge(watch.shared)
        #expect(phone.pendingConflict == nil)
    }

    @Test
    func concurrent_opposite_resolutions_converge_on_the_same_result() {
        var phone = CookingSessionLocalState(originID: "phone")
        var watch = CookingSessionLocalState(originID: "watch")
        phone.start(Self.snapshot(recipeID: "pasta"))
        watch.start(Self.snapshot(recipeID: "soup"))
        let phoneShared = phone.shared
        phone.merge(watch.shared)
        watch.merge(phoneShared)

        // Both keep their own session before seeing the other's choice.
        phone.resolveConflict(keepingLocalSession: true)
        watch.resolveConflict(keepingLocalSession: true)
        let phoneResolved = phone.shared
        phone.merge(watch.shared)
        watch.merge(phoneResolved)

        // The deterministic choice wins without treating either Keep as End.
        #expect(phone.activeSnapshot?.recipeID == "soup")
        #expect(watch.activeSnapshot?.recipeID == "soup")
        watch.endActiveSession()
        phone.merge(watch.shared)
        #expect(phone.activeSnapshot == nil)
        #expect(watch.activeSnapshot == nil)
    }

    @Test
    func ending_during_a_conflict_promotes_the_peer_session() {
        var phone = CookingSessionLocalState(originID: "phone")
        var watch = CookingSessionLocalState(originID: "watch")
        phone.start(Self.snapshot(recipeID: "pasta"))
        watch.start(Self.snapshot(recipeID: "soup"))
        phone.merge(watch.shared)

        phone.endActiveSession()
        watch.merge(phone.shared)

        #expect(phone.activeSnapshot?.recipeID == "soup")
        #expect(watch.activeSnapshot?.recipeID == "soup")
        #expect(watch.pendingConflict == nil)
    }

    @Test
    func local_start_replaces_known_session_without_prompting_the_peer() {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot(recipeID: "pasta"))
        var watch = CookingSessionLocalState(originID: "watch")
        watch.merge(phone.shared)

        watch.start(Self.snapshot(recipeID: "soup"))
        phone.merge(watch.shared)

        #expect(phone.activeSnapshot?.recipeID == "soup")
        #expect(phone.pendingConflict == nil)
    }

    @Test
    func state_survives_relaunch_and_keeps_rejecting_retired_replays() throws {
        var phone = CookingSessionLocalState(originID: "phone")
        phone.start(Self.snapshot())
        let oldActive = phone.shared
        phone.endActiveSession()

        let encoded = try #require(phone.encodedString())
        var relaunched = try #require(CookingSessionLocalState.decoded(from: encoded))
        relaunched.merge(oldActive)

        #expect(relaunched == phone)
        #expect(relaunched.activeSnapshot == nil)
        relaunched.start(Self.snapshot())
        #expect(relaunched.activeRecord?.sessionID.sequence == 2)
    }

    @Test
    func legacy_snapshot_migrates_to_a_local_session_only_when_active() {
        let active = CookingSessionLocalState.migrating(
            legacySnapshot: Self.snapshot(),
            originID: "phone"
        )
        let ended = CookingSessionLocalState.migrating(
            legacySnapshot: Self.snapshot().endingSession(),
            originID: "phone"
        )

        #expect(active.activeSnapshot?.recipeID == "recipe-1")
        #expect(ended.activeSnapshot == nil)
    }

    @Test
    func a_resolved_loser_stays_suppressed_after_restart_and_delayed_delivery() throws {
        var phone = CookingSessionLocalState(originID: "phone")
        var watch = CookingSessionLocalState(originID: "watch")
        phone.start(Self.snapshot(recipeID: "pasta"))
        watch.start(Self.snapshot(recipeID: "soup"))
        let delayedWatch = watch.shared
        phone.merge(watch.shared)
        phone.resolveConflict(keepingLocalSession: true)
        let encoded = try #require(phone.encodedString())
        var restored = try #require(CookingSessionLocalState.decoded(from: encoded))
        restored.merge(delayedWatch)
        #expect(restored.activeSnapshot?.recipeID == "pasta")
        #expect(restored.pendingConflict == nil)
        restored.endActiveSession()
        restored.merge(delayedWatch)
        #expect(restored.activeSnapshot == nil)
        #expect(restored.pendingConflict == nil)
    }

    @Test
    func terminal_state_wins_over_concurrent_conflict_choices() {
        var phone = CookingSessionLocalState(originID: "phone")
        var watch = CookingSessionLocalState(originID: "watch")
        phone.start(Self.snapshot(recipeID: "pasta"))
        watch.start(Self.snapshot(recipeID: "soup"))
        let phoneStarted = phone.shared
        phone.merge(watch.shared)
        watch.merge(phoneStarted)
        phone.resolveConflict(keepingLocalSession: true)
        watch.resolveConflict(keepingLocalSession: true)
        watch.endActiveSession()
        let ended = watch.shared
        watch.merge(phone.shared)
        phone.merge(ended)
        #expect(phone.activeSnapshot == nil)
        #expect(watch.activeSnapshot == nil)
    }

    @Test
    func unsafe_counters_and_unsupported_local_formats_are_rejected() throws {
        let invalid = CookingSessionSyncState(current: .init(
            sessionID: .init(originID: "peer", sequence: Int.max),
            revision: Int.max,
            editorID: "peer",
            snapshot: Self.snapshot()
        ))
        let encoded = try #require(invalid.encodedString())
        #expect(CookingSessionSyncState.decoding(encoded) == .malformed)
        let local = CookingSessionLocalState(originID: "phone", shared: invalid)
        #expect(CookingSessionLocalState.decoded(from: try #require(local.encodedString())) == nil)
    }
}
