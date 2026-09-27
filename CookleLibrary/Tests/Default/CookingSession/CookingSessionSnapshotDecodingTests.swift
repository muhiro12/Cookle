@testable import CookleLibrary
import Foundation
import Testing

struct CookingSessionSnapshotDecodingTests {
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
}
