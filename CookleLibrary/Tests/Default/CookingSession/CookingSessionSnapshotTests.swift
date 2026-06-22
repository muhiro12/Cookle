@testable import CookleLibrary
import Foundation
import Testing

struct CookingSessionSnapshotTests {
    @Test
    func init_clamps_step_index_to_bounds() {
        let snapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: [
                "Boil water",
                "Cook pasta"
            ],
            currentStepIndex: 99,
            activeTimer: nil,
            updatedAt: Date(timeIntervalSinceReferenceDate: 100),
            isActive: true
        )

        #expect(snapshot.currentStepIndex == 1)
        #expect(snapshot.currentStep == "Cook pasta")
    }

    @Test
    func encode_and_decode_round_trip_preserves_snapshot() {
        let snapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: [
                "Boil water",
                "Cook pasta"
            ],
            currentStepIndex: 1,
            activeTimer: .init(
                durationSeconds: 600,
                startedAt: Date(timeIntervalSinceReferenceDate: 200)
            ),
            updatedAt: Date(timeIntervalSinceReferenceDate: 300),
            isActive: true
        )

        let encodedValue = snapshot.encodedString()
        let decodedSnapshot = encodedValue.flatMap(
            CookingSessionSnapshot.decoded(from:)
        )

        #expect(decodedSnapshot == snapshot)
    }

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
    func suggestedTimer_parses_minutes_from_supported_patterns() {
        let englishShort = CookingTimerSuggestionParser.suggestedTimer(
            for: "Bake for 10 min until golden."
        )
        let englishLong = CookingTimerSuggestionParser.suggestedTimer(
            for: "Rest for 10 minutes before serving."
        )
        let japanese = CookingTimerSuggestionParser.suggestedTimer(
            for: "１０分ほど煮込む。"
        )

        #expect(englishShort?.minutes == 10)
        #expect(englishLong?.minutes == 10)
        #expect(japanese?.minutes == 10)
    }

    @Test
    func suggestedTimer_returns_nil_when_step_has_no_supported_pattern() {
        let suggestion = CookingTimerSuggestionParser.suggestedTimer(
            for: "Mix everything together and serve."
        )

        #expect(suggestion == nil)
    }

    @Test
    func timerStatus_reports_running_and_expired_states() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 100)
        let snapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: ["Boil water"],
            currentStepIndex: 0,
            activeTimer: .init(
                durationSeconds: 300,
                startedAt: startedAt
            ),
            updatedAt: startedAt,
            isActive: true
        )

        #expect(
            snapshot.timerStatus(
                at: Date(timeIntervalSinceReferenceDate: 220)
            ) == .running(remainingSeconds: 180)
        )
        #expect(
            snapshot.requiresTimerFollowUp(
                at: Date(timeIntervalSinceReferenceDate: 401)
            )
        )
        #expect(
            snapshot.timerStatus(
                at: Date(timeIntervalSinceReferenceDate: 401)
            ) == .expired
        )
    }
}
