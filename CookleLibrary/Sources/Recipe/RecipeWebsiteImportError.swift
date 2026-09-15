/// Failures that require the user to choose or shorten the source text.
public enum RecipeWebsiteImportError: Error, Equatable, Sendable {
    case contentTooLarge
    case multipleRecipes
    case noContent
}
