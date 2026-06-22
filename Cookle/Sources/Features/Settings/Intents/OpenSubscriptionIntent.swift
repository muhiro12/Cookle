import AppIntents

struct OpenSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Subscription Settings"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(.settingsSubscription)
        return .result()
    }
}
