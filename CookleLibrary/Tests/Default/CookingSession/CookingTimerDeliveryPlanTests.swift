@testable import CookleLibrary
import Foundation
import Testing

struct CookingTimerDeliveryPlanTests {
    private let startDate = CookingTimerFixture.startDate

    @Test
    func current_alert_is_nil_without_timer_or_after_session_end() {
        var state = CookingTimerFixture.state()
        #expect(CookingTimerAlert.current(in: state) == nil)

        state.updateActiveSession { snapshot in
            snapshot.startingTimer(durationMinutes: 5, startedAt: startDate)
        }
        #expect(CookingTimerAlert.current(in: state) != nil)

        state.endActiveSession(updatedAt: startDate.addingTimeInterval(10))
        #expect(CookingTimerAlert.current(in: state) == nil)
    }

    @Test
    func current_alert_derives_deadline_and_step_from_session() throws {
        let state = CookingTimerFixture.state(timerMinutes: 5, stepIndex: 1)
        let alert = try #require(CookingTimerAlert.current(in: state))

        #expect(alert.recipeID == "recipe-1")
        #expect(alert.recipeName == "Pasta")
        #expect(alert.endsAt == startDate.addingTimeInterval(300))
        #expect(alert.state.stepNumber == 2)
        #expect(alert.state.stepCount == 3)
        #expect(alert.isRunning(at: startDate.addingTimeInterval(299)))
        #expect(alert.isRunning(at: startDate.addingTimeInterval(300)) == false)
    }

    @Test
    func repeat_changes_timer_key_but_keeps_session_key() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))

        state.updateActiveSession { snapshot in
            snapshot.repeatingTimer(startedAt: startDate.addingTimeInterval(400))
        }
        let repeated = try #require(CookingTimerAlert.current(in: state))

        #expect(repeated.sessionKey == original.sessionKey)
        #expect(repeated.timerKey != original.timerKey)
    }

    @Test
    func step_change_keeps_timer_key() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))

        state.updateActiveSession { snapshot in
            snapshot.advancingToNextStep(updatedAt: startDate.addingTimeInterval(20))
        }
        let advanced = try #require(CookingTimerAlert.current(in: state))

        #expect(advanced.timerKey == original.timerKey)
        #expect(advanced.state != original.state)
    }

    @Test
    func new_session_for_same_recipe_changes_both_keys() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))

        state.start(CookingTimerFixture.snapshot(timerMinutes: 5))
        let restarted = try #require(CookingTimerAlert.current(in: state))

        #expect(restarted.sessionKey != original.sessionKey)
        #expect(restarted.timerKey != original.timerKey)
    }

    @Test
    func running_timer_is_scheduled_once() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))

        let first = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: nil,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: startDate
        )
        let second = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: alert.timerKey,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: startDate.addingTimeInterval(120)
        )

        #expect(first == .init(removesPending: false, removesDelivered: false, schedules: alert))
        #expect(second == .init(removesPending: false, removesDelivered: false, schedules: nil))
    }

    @Test
    func unauthorized_running_timer_is_not_scheduled() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))

        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: nil,
            deliveredTimerKey: nil,
            isAuthorized: false,
            now: startDate
        )

        #expect(changes == .init(removesPending: false, removesDelivered: false, schedules: nil))
    }

    @Test
    func cancellation_removes_pending_and_delivered() {
        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: nil,
            pendingTimerKey: "old",
            deliveredTimerKey: "older",
            isAuthorized: true,
            now: startDate
        )

        #expect(changes == .init(removesPending: true, removesDelivered: true, schedules: nil))
    }

    @Test
    func repeat_replaces_delivered_alert_with_new_pending_alert() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))
        let repeatDate = startDate.addingTimeInterval(400)
        state.updateActiveSession { snapshot in
            snapshot.repeatingTimer(startedAt: repeatDate)
        }
        let repeated = try #require(CookingTimerAlert.current(in: state))

        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: repeated,
            pendingTimerKey: nil,
            deliveredTimerKey: original.timerKey,
            isAuthorized: true,
            now: repeatDate
        )

        #expect(changes == .init(removesPending: false, removesDelivered: true, schedules: repeated))
    }

    @Test
    func replacing_running_timer_reschedules_pending_alert() throws {
        var state = CookingTimerFixture.state(timerMinutes: 5)
        let original = try #require(CookingTimerAlert.current(in: state))
        state.updateActiveSession { snapshot in
            snapshot.startingTimer(durationMinutes: 10, startedAt: startDate.addingTimeInterval(30))
        }
        let replacement = try #require(CookingTimerAlert.current(in: state))

        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: replacement,
            pendingTimerKey: original.timerKey,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: startDate.addingTimeInterval(30)
        )

        #expect(changes == .init(removesPending: true, removesDelivered: false, schedules: replacement))
    }

    @Test
    func relaunch_after_expiry_keeps_delivered_alert_and_schedules_nothing() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))
        let relaunchDate = startDate.addingTimeInterval(3_600)

        let withDelivered = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: nil,
            deliveredTimerKey: alert.timerKey,
            isAuthorized: true,
            now: relaunchDate
        )
        let withoutDelivered = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: nil,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: relaunchDate
        )

        #expect(withDelivered == .init(removesPending: false, removesDelivered: false, schedules: nil))
        #expect(withoutDelivered == .init(removesPending: false, removesDelivered: false, schedules: nil))
    }
}
