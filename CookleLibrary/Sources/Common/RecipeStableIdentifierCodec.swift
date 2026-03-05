import Foundation
import SwiftData

/// Canonical codec for stable recipe identifiers shared across targets.
public enum RecipeStableIdentifierCodec {
    /// Encodes a persistent recipe identifier into a stable string.
    public static func encode(
        _ recipeID: Recipe.ID
    ) throws -> String {
        try recipeID.base64Encoded()
    }

    /// Encodes a persistent recipe identifier into a stable string when possible.
    public static func encodeIfPossible(
        _ recipeID: Recipe.ID
    ) -> String? {
        try? encode(recipeID)
    }

    /// Returns a stable identifier for a recipe, with a deterministic fallback.
    public static func stableIdentifier(
        for recipe: Recipe
    ) -> String {
        if let encodedIdentifier = encodeIfPossible(recipe.id) {
            return encodedIdentifier
        }
        return String(describing: recipe.persistentModelID)
    }

    /// Decodes a stable string into a persistent recipe identifier.
    public static func decode(
        _ stableIdentifier: String
    ) throws -> Recipe.ID {
        try .init(base64Encoded: stableIdentifier)
    }

    /// Resolves a recipe from a stable identifier.
    public static func recipe(
        from stableIdentifier: String,
        context: ModelContext
    ) throws -> Recipe? {
        guard let recipeID = try? decode(stableIdentifier) else {
            return nil
        }
        return try context.fetchFirst(
            .recipes(.idIs(recipeID))
        )
    }
}
