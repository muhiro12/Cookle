@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct WatchCompanionContextTests {
    private static let legacyPayload = """
    {"currentStepIndex":0,"isActive":true,"recipeID":"recipe-1",\
    "recipeName":"Pasta","steps":["Boil water"],"updatedAt":300}
    """.replacingOccurrences(of: "\\\n", with: "")

    private static func activeState() -> CookingSessionLocalState {
        var state = CookingSessionLocalState(originID: "phone")
        state.start(
            .init(
                recipeID: "recipe-1",
                recipeName: "Pasta",
                steps: ["Boil water"],
                currentStepIndex: 0,
                activeTimer: nil,
                updatedAt: .init(timeIntervalSinceReferenceDate: 300),
                isActive: true
            )
        )
        return state
    }

    @Test
    func missing_malformed_and_unsupported_payloads_keep_local_state() {
        let original = Self.activeState()
        let contexts: [[String: Any]] = [
            [:],
            [WatchCompanionContext.sessionStateKey: "not json"],
            [WatchCompanionContext.sessionStateKey: #"{"formatVersion":99}"#],
            [WatchCompanionContext.legacySnapshotKey: ""]
        ]
        for context in contexts {
            var state = original
            let result = CookingSessionOperations.applyReceivedContext(context, to: &state)
            #expect(result.changed == false)
            #expect(state == original)
        }

        var state = original
        let unsupported = CookingSessionOperations.applyReceivedContext(
            [WatchCompanionContext.sessionStateKey: #"{"formatVersion":99}"#],
            to: &state
        )
        #expect(unsupported.peerStatus == .thisDeviceRequiresUpdate)
    }

    @Test
    func legacy_peer_payload_is_gated_and_reports_an_update_requirement() {
        var state = Self.activeState()
        let original = state

        let result = CookingSessionOperations.applyReceivedContext(
            [WatchCompanionContext.legacySnapshotKey: Self.legacyPayload],
            to: &state
        )

        #expect(result.changed == false)
        #expect(result.peerStatus == .peerRequiresUpdate)
        #expect(state == original)
    }

    @Test
    func composed_context_carries_state_and_catalog_but_never_the_legacy_key() {
        let catalog = RecentRecipeCatalog.bounded(
            [
                .init(
                    recipeID: "recipe-1",
                    title: "Pasta",
                    steps: ["Boil"],
                    updatedAt: .init(timeIntervalSinceReferenceDate: 1)
                )
            ],
            generatedAt: .init(timeIntervalSinceReferenceDate: 2)
        )
        let state = Self.activeState()

        let context = WatchCompanionContext.composed(
            sessionState: state.shared,
            recentRecipeCatalog: catalog
        )

        #expect(context[WatchCompanionContext.legacySnapshotKey] == nil)
        #expect(WatchCompanionContext.recentRecipeCatalog(in: context) == catalog)
        var watch = CookingSessionLocalState(originID: "watch")
        let result = CookingSessionOperations.applyReceivedContext(context, to: &watch)
        #expect(result.changed)
        #expect(result.peerStatus == .compatible)
        #expect(watch.activeSnapshot == state.activeSnapshot)
    }

    @Test
    func legacy_snapshot_fixture_still_decodes_for_local_recovery() {
        let snapshot = CookingSessionSnapshot.decoded(from: Self.legacyPayload)
        let state = CookingSessionLocalState.migrating(legacySnapshot: snapshot)

        #expect(state.activeSnapshot?.recipeName == "Pasta")
    }
}
