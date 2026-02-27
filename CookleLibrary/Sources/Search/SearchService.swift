import Foundation
import SwiftData

/// Legacy search aggregator over name, ingredients and categories.
@preconcurrency
@MainActor
public enum SearchService {
    /// Searches recipes by name, ingredients and categories.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text.
    /// - Returns: Matching recipes (deduplicated).
    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
        var recipes = try context.fetch(
            .recipes(.nameContains(text))
        )
        let ingredients = try context.fetch(
            text.count < 3
                ? .ingredients(.valueIs(text))
                : .ingredients(.valueContains(text))
        )
        let categories = try context.fetch(
            text.count < 3
                ? .categories(.valueIs(text))
                : .categories(.valueContains(text))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        recipes = Array(Set(recipes))
        return recipes
    }
}
