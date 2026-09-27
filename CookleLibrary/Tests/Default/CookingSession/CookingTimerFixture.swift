@testable import CookleLibrary
import Foundation

/// Shared cooking session states for timer delivery tests.
enum CookingTimerFixture {
    private enum Value {
        static let activityDurationSeconds: TimeInterval = 60
        static let stepCount = 3
        static let startTimeInterval: TimeInterval = 1_000
    }

    static let startDate = Date(timeIntervalSinceReferenceDate: Value.startTimeInterval)

    static func snapshot(
        timerMinutes: Int? = nil,
        stepIndex: Int = 0
    ) -> CookingSessionSnapshot {
        let snapshot = CookingSessionSnapshot(
            recipeID: "recipe-1",
            recipeName: "Pasta",
            steps: [
                "Boil water",
                "Cook pasta for 5 min",
                "Serve"
            ],
            currentStepIndex: stepIndex,
            activeTimer: nil,
            updatedAt: startDate,
            isActive: true
        )
        guard let timerMinutes else {
            return snapshot
        }
        return snapshot.startingTimer(
            durationMinutes: timerMinutes,
            startedAt: startDate
        )
    }

    static func state(
        timerMinutes: Int? = nil,
        stepIndex: Int = 0
    ) -> CookingSessionLocalState {
        var state = CookingSessionLocalState(originID: "phone")
        state.start(
            snapshot(
                timerMinutes: timerMinutes,
                stepIndex: stepIndex
            )
        )
        return state
    }

    static func activityState() -> CookingTimerActivityState {
        .init(
            timerStartedAt: startDate,
            timerEndsAt: startDate.addingTimeInterval(Value.activityDurationSeconds),
            stepNumber: 1,
            stepCount: Value.stepCount
        )
    }
}
