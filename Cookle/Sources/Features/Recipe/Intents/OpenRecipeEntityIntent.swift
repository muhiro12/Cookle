import AppIntents
import MHPlatform

/// Opens a recipe from Spotlight, Siri, and Shortcuts.
///
/// Spotlight opens an indexed `RecipeEntity` through its `OpenIntent`, whose
/// parameter must be named `target`. This intent takes over the Shortcuts
/// library entry from `OpenRecipeIntent` instead of renaming that intent's
/// `recipe` parameter, which saved shortcuts still reference.
struct OpenRecipeEntityIntent: OpenIntent {
    static var title: LocalizedStringResource {
        "Open Recipe"
    }

    @Parameter(title: "Recipe")
    var target: RecipeEntity

    @Dependency private var routePipeline: MHAppRoutePipeline<CookleRoute>

    @MainActor
    func perform() async -> some IntentResult {
        CookleRouteIntentSupport.open(
            .recipeDetail(target.id)
        )
        // The system runs this after the app is already active, so the
        // activation task that drains stored routes has finished. Drain the
        // route now instead of leaving it for the next activation.
        await routePipeline.synchronizePendingRoutesIfPossible()
        return .result()
    }
}
