import Foundation

/// Describes the single quick-return destination shown at the top of the recipe list.
public struct RecipeTopReturnTarget: Equatable, Sendable {
    /// Distinguishes whether the target resumes cooking or reopens the last viewed recipe.
    public enum Kind: Sendable {
        case activeCookingSession
        case lastOpenedRecipe
    }

    public let kind: Kind
    public let recipeName: String
    public let recipeStableIdentifier: String

    /// Creates a recipe-list quick-return target.
    public init(
        kind: Kind,
        recipeName: String,
        recipeStableIdentifier: String
    ) {
        self.kind = kind
        self.recipeName = recipeName
        self.recipeStableIdentifier = recipeStableIdentifier
    }
}
