import CookleLibrary
import Testing

struct CookleNotificationIdentifiersTests {
    @Test(arguments: ["dailyRecipeSuggestion.20261022-dinner", "dailyRecipeSuggestionTest"])
    func canonical_suggestions_are_managed_even_without_metadata(_ identifier: String) {
        #expect(CookleNotificationIdentifiers.isManagedSuggestion(identifier: identifier, contentKind: nil))
    }

    @Test
    func request_ownership_does_not_depend_on_a_previous_spelling() {
        #expect(CookleNotificationIdentifiers.isManagedSuggestion(
            identifier: "an-arbitrary-request-id",
            contentKind: "recipeSuggestion"
        ))
        #expect(CookleNotificationIdentifiers.isCookingTimer(
            identifier: "another-arbitrary-request-id",
            contentKind: "cookingTimer"
        ))
        #expect(!CookleNotificationIdentifiers.isManagedSuggestion(
            identifier: "another-arbitrary-request-id",
            contentKind: "cookingTimer"
        ))
        #expect(!CookleNotificationIdentifiers.isCookingTimer(
            identifier: "an-arbitrary-request-id",
            contentKind: "recipeSuggestion"
        ))
    }

    @Test
    func meal_suppression_only_applies_to_current_scheduled_suggestions() {
        #expect(CookleNotificationIdentifiers.isScheduledSuggestionIdentifier("dailyRecipeSuggestion.20261022-dinner"))
        #expect(!CookleNotificationIdentifiers.isScheduledSuggestionIdentifier("dailyRecipeSuggestionTest"))
    }

    @Test
    func unrelated_notifications_are_not_managed() {
        let identifier = "anotherFeature"
        #expect(!CookleNotificationIdentifiers.isManagedSuggestion(identifier: identifier, contentKind: nil))
        #expect(!CookleNotificationIdentifiers.isScheduledSuggestionIdentifier(identifier))
        #expect(!CookleNotificationIdentifiers.isCookingTimer(identifier: identifier, contentKind: nil))
        #expect(
            CookleNotificationIdentifiers.pendingCookingTimerKey(
                identifier: identifier,
                contentKind: nil,
                timerKey: "a-timer"
            ) == nil
        )
    }

    @Test
    func a_noncanonical_reservation_is_replaced_even_when_its_timer_is_unchanged() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))
        let key = CookleNotificationIdentifiers.pendingCookingTimerKey(
            identifier: "an-arbitrary-request-id",
            contentKind: "cookingTimer",
            timerKey: alert.timerKey
        )
        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: key,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: CookingTimerFixture.startDate
        )

        #expect(changes == .init(removesPending: true, removesDelivered: false, schedules: alert))
    }

    @Test
    func a_noncanonical_reservation_is_removed_when_the_timer_has_stopped() {
        let key = CookleNotificationIdentifiers.pendingCookingTimerKey(
            identifier: "an-arbitrary-request-id",
            contentKind: "cookingTimer",
            timerKey: "a-timer"
        )
        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: nil,
            pendingTimerKey: key,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: CookingTimerFixture.startDate
        )

        #expect(changes == .init(removesPending: true, removesDelivered: false, schedules: nil))
    }

    @Test
    func a_current_reservation_is_reused_without_duplicate_delivery() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))
        let key = CookleNotificationIdentifiers.pendingCookingTimerKey(
            identifier: "cookingTimer",
            contentKind: nil,
            timerKey: alert.timerKey
        )
        let changes = CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: key,
            deliveredTimerKey: nil,
            isAuthorized: true,
            now: CookingTimerFixture.startDate
        )

        #expect(changes == .init(removesPending: false, removesDelivered: false, schedules: nil))
    }
}
