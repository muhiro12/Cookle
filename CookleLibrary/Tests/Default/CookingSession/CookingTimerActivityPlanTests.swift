@testable import CookleLibrary
import Foundation
import Testing

struct CookingTimerActivityPlanTests {
    private let startDate = CookingTimerFixture.startDate

    @Test
    func new_timer_requests_activity_only_when_allowed() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))

        let allowed = CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: [],
            allowsRequest: true,
            now: startDate
        )
        let disallowed = CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: [],
            allowsRequest: false,
            now: startDate
        )

        #expect(allowed == [.request(alert)])
        #expect(disallowed.isEmpty)
    }

    @Test
    func expired_timer_never_requests_activity() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))

        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: [],
            allowsRequest: true,
            now: alert.endsAt
        )

        #expect(changes.isEmpty)
    }

    @Test
    func existing_activity_is_reused_and_updated_for_step_change() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))
        state.updateActiveSession { snapshot in
            snapshot.advancingToNextStep(updatedAt: startDate.addingTimeInterval(20))
        }
        let advanced = try #require(CookingTimerAlert.current(in: state))
        let activity = CookingTimerDeliveryPlan.ActivityRecord(
            id: "activity-1",
            sessionKey: original.sessionKey,
            state: original.state
        )

        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: advanced,
            existing: [activity],
            allowsRequest: false,
            now: startDate.addingTimeInterval(20)
        )
        let unchanged = CookingTimerDeliveryPlan.activityChanges(
            for: original,
            existing: [activity],
            allowsRequest: true,
            now: startDate
        )

        #expect(changes == [.update(id: "activity-1", alert: advanced)])
        #expect(unchanged.isEmpty)
    }

    @Test
    func repeat_updates_existing_activity_with_new_deadline() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))
        state.updateActiveSession { snapshot in
            snapshot.repeatingTimer(startedAt: startDate.addingTimeInterval(400))
        }
        let repeated = try #require(CookingTimerAlert.current(in: state))

        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: repeated,
            existing: [
                .init(id: "activity-1", sessionKey: original.sessionKey, state: original.state)
            ],
            allowsRequest: true,
            now: startDate.addingTimeInterval(400)
        )

        #expect(changes == [.update(id: "activity-1", alert: repeated)])
    }

    @Test
    func cancellation_ends_every_activity() {
        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: nil,
            existing: [
                .init(id: "a", sessionKey: "s", state: CookingTimerFixture.activityState()),
                .init(id: "b", sessionKey: "t", state: CookingTimerFixture.activityState())
            ],
            allowsRequest: true,
            now: startDate
        )

        #expect(changes == [.end(id: "a"), .end(id: "b")])
    }

    @Test
    func other_session_and_duplicate_activities_end() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))

        let changes = CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: [
                .init(id: "old", sessionKey: "other", state: CookingTimerFixture.activityState()),
                .init(id: "kept", sessionKey: alert.sessionKey, state: alert.state),
                .init(id: "duplicate", sessionKey: alert.sessionKey, state: alert.state)
            ],
            allowsRequest: true,
            now: startDate
        )

        #expect(changes == [.end(id: "old"), .end(id: "duplicate")])
    }
}
