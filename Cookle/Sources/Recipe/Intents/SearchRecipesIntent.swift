import AppIntents
import SwiftData

struct SearchRecipesIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, text: String)
    typealias Output = [Recipe]

    nonisolated static var title: LocalizedStringResource {
        "Search Recipes"
    }

    static func perform(_ input: Input) throws -> Output {
        let (context, text) = input
        var recipes = try context.fetch(
            .recipes(.nameContains(text))
        )
        let ingredients = try context.fetch(
            text.count < 3 ? .ingredients(.valueIs(text)) : .ingredients(.valueContains(text))
        )
        let categories = try context.fetch(
            text.count < 3 ? .categories(.valueIs(text)) : .categories(.valueContains(text))
        )
        recipes += ingredients.flatMap(\.recipes.orEmpty)
        recipes += categories.flatMap(\.recipes.orEmpty)
        return Array(Set(recipes))
    }

    func perform() throws -> some IntentResult {
        .result()
    }
}
