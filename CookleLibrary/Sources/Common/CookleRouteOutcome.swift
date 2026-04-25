/// Navigation intents that adapters present after resolving a `CookleRoute`.
public enum CookleRouteOutcome {
    /// Opens the default home experience without focusing a specific record.
    case home
    /// Opens the diary flow and optionally focuses a resolved diary.
    case diary(diary: Diary?)
    /// Opens the recipe flow and optionally focuses a resolved recipe.
    case recipe(recipe: Recipe?)
    /// Opens the photo flow and optionally focuses a resolved photo asset.
    case photo(photo: Photo?)
    /// Opens category browsing and optionally focuses a resolved category.
    case tagCategory(category: Category?)
    /// Opens ingredient browsing and optionally focuses a resolved ingredient.
    case tagIngredient(ingredient: Ingredient?)
    /// Opens search with an optional prefilled query.
    case search(query: String?)
    /// Opens the settings root screen.
    case settings
    /// Opens the subscription section inside settings.
    case settingsSubscription
    /// Opens the license section inside settings.
    case settingsLicense
}
