import AppIntents

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
