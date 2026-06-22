import AppIntents

struct OpenRecipesIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Recipes"
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(.recipe)
        return .result()
    }
}
