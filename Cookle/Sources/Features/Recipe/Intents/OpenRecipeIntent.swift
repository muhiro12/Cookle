import AppIntents

/// Runs shortcuts saved before `OpenRecipeEntityIntent` replaced this intent
/// in the Shortcuts library.
struct OpenRecipeIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Open Recipe"
    }

    static var openAppWhenRun: Bool {
        true
    }

    static var isDiscoverable: Bool {
        false
    }

    @Parameter(title: "Recipe")
    private var recipe: RecipeEntity

    @MainActor
    func perform() -> some IntentResult {
        CookleRouteIntentSupport.open(
            .recipeDetail(recipe.id)
        )
        return .result()
    }
}
