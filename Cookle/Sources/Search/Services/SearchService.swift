import Foundation
import SwiftData

@MainActor
enum SearchService {
    static func search(context: ModelContext, text: String) throws -> [Recipe] {
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

