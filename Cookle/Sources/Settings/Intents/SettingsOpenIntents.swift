import AppIntents

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Settings"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(.settings)
        return .result()
    }
}

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

struct OpenLicenseIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open License Settings"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(.settingsLicense)
        return .result()
    }
}
