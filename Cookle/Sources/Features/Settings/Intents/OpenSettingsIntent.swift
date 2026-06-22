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
