/// Describes the navigation target produced by `CookleRouteExecutor`.
public enum CookleRouteOutcome {
    /// Shows the home screen.
    case home
    /// Shows the diary flow, optionally focusing an existing diary.
    case diary(diary: Diary?)
    /// Shows the recipe flow, optionally focusing an existing recipe.
    case recipe(recipe: Recipe?)
    /// Shows the search screen with an optional query.
    case search(query: String?)
    /// Shows the settings root screen.
    case settings
    /// Shows the subscription settings screen.
    case settingsSubscription
    /// Shows the license settings screen.
    case settingsLicense
}
