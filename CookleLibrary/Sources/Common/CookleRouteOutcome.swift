/// Navigation intents that adapters present after resolving a `CookleRoute`.
public enum CookleRouteOutcome {
    /// Opens the default home experience without focusing a specific record.
    case home
    /// Opens the diary flow and optionally focuses a resolved diary.
    case diary(diary: Diary?)
    /// Opens the recipe flow and optionally focuses a resolved recipe.
    case recipe(recipe: Recipe?)
    /// Opens search with an optional prefilled query.
    case search(query: String?)
    /// Opens the settings root screen.
    case settings
    /// Opens the subscription section inside settings.
    case settingsSubscription
    /// Opens the license section inside settings.
    case settingsLicense
}
