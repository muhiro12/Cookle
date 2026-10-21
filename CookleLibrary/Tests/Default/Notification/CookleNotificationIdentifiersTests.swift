import CookleLibrary
import Testing

struct CookleNotificationIdentifiersTests {
    @Test(arguments: [
        "dailyRecipeSuggestion.20261022-dinner",
        "daily-recipe-suggestion-20261022-dinner"
    ])
    func current_and_released_suggestions_are_replaced_and_suppressed(_ identifier: String) {
        #expect(CookleNotificationIdentifiers.isManagedSuggestionIdentifier(identifier))
        #expect(CookleNotificationIdentifiers.isScheduledSuggestionIdentifier(identifier))
    }

    @Test(arguments: ["dailyRecipeSuggestionTest", "daily-recipe-suggestion-test"])
    func preview_notifications_are_cleaned_up_but_never_meal_suppressed(_ identifier: String) {
        #expect(CookleNotificationIdentifiers.isManagedSuggestionIdentifier(identifier))
        #expect(!CookleNotificationIdentifiers.isScheduledSuggestionIdentifier(identifier))
    }

    @Test(arguments: ["browseRecipes", "browse_recipes"])
    func current_and_delivered_browse_actions_still_open_recipes(_ identifier: String) {
        #expect(CookleNotificationIdentifiers.isBrowseRecipesAction(identifier))
    }

    @Test
    func unrelated_notifications_are_not_managed() {
        let identifier = "anotherFeature"
        #expect(!CookleNotificationIdentifiers.isManagedSuggestionIdentifier(identifier))
        #expect(!CookleNotificationIdentifiers.isScheduledSuggestionIdentifier(identifier))
        #expect(!CookleNotificationIdentifiers.isBrowseRecipesAction(identifier))
        #expect(!CookleNotificationIdentifiers.isCookingTimerIdentifier(identifier))
        #expect(
            CookleNotificationIdentifiers.pendingCookingTimerKey(
                identifier: identifier,
                timerKey: "a-timer"
            ) == nil
        )
    }

    @Test
    func a_legacy_reservation_is_replaced_even_when_its_timer_is_unchanged() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))
        let key = CookleNotificationIdentifiers.pendingCookingTimerKey(
            identifier: "cooking-timer",
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
        #expect(Set(CookleNotificationIdentifiers.cookingTimerIdentifiers) == ["cookingTimer", "cooking-timer"])
    }

    @Test
    func a_current_reservation_is_reused_without_duplicate_delivery() throws {
        let alert = try #require(CookingTimerAlert.current(in: CookingTimerFixture.state(timerMinutes: 5)))
        let key = CookleNotificationIdentifiers.pendingCookingTimerKey(
            identifier: "cookingTimer",
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
        #expect(CookleNotificationIdentifiers.isCookingTimerIdentifier("cooking-timer"))
    }
}
