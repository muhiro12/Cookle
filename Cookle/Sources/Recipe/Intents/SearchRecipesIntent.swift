import AppIntents
import SwiftData

struct SearchRecipesIntent: AppIntent, IntentPerformer {
    typealias Input = (context: ModelContext, searchText: String)
    typealias Output = [Recipe]

    nonisolated static var title: LocalizedStringResource {
        "Search Recipes"
    }

    @Parameter(title: "Search for Recipes")
    private var searchText: String

    @Dependency private var modelContainer: ModelContainer

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

    func perform() throws -> some ReturnsValue<[RecipeEntity]> {
        .result(
            value: try Self.perform(
                (
                    context: modelContainer.mainContext,
                    searchText: searchText
                )
            )
            .compactMap(RecipeEntity.init)
        )
    }
}
