import Foundation
import SwiftData

/// Canonical codec for stable recipe identifiers shared across targets.
public enum RecipeStableIdentifierCodec {
    /// Encodes a persistent recipe identifier into a stable string.
    public static func encode(
        _ recipeID: Recipe.ID
    ) throws -> String {
        try PersistentModelStableIdentifierCodec.encode(recipeID)
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
        PersistentModelStableIdentifierCodec.stableIdentifier(for: recipe)
    }

    /// Decodes a stable string into a persistent recipe identifier.
    public static func decode(
        _ stableIdentifier: String
    ) throws -> Recipe.ID {
        try PersistentModelStableIdentifierCodec.decode(stableIdentifier)
    }

    /// Resolves a recipe from a stable identifier.
    public static func recipe(
        from stableIdentifier: String,
        context: ModelContext
    ) throws -> Recipe? {
        guard let identifier = try? decode(stableIdentifier) else {
            return nil
        }
        return try context.fetchFirst(.recipes(.idIs(identifier)))
    }

    /// Resolves saved identifiers, preserving input order and repetitions.
    /// Invalid identifiers and recipes missing from this store are omitted.
    public static func recipes(
        from stableIdentifiers: [String],
        context: ModelContext
    ) throws -> [Recipe] {
        let identifiers = stableIdentifiers.compactMap { identifier in
            try? decode(identifier)
        }
        guard !identifiers.isEmpty else {
            return []
        }
        var recipesByIdentifier = [Recipe.ID: Recipe]()
        // Array membership against persistentModelID drops saved matches on iOS
        // 18.6. Exact-ID predicates work there; fetch each distinct ID only once.
        for identifier in Set(identifiers) {
            if let recipe = try context.fetchFirst(.recipes(.idIs(identifier))) {
                recipesByIdentifier[identifier] = recipe
            }
        }
        return identifiers.compactMap { identifier in
            recipesByIdentifier[identifier]
        }
    }
}
