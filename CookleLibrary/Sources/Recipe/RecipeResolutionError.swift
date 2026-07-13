/// Errors thrown while resolving stored recipes.
public enum RecipeResolutionError: Error, Equatable, Sendable {
    /// A stable identifier no longer refers to a stored recipe.
    case recipeNotFound
}
