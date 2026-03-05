import AppIntents
import SwiftData

struct RecipeEntityQuery: EntityStringQuery {
    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [RecipeEntity.ID]) throws -> [RecipeEntity] {
        try identifiers.compactMap { id in
            let persistentIdentifier = try RecipeStableIdentifierCodec.decode(
                id
            )
            guard let recipe = try modelContainer.mainContext.fetchFirst(
                .recipes(.idIs(persistentIdentifier))
            ) else {
                return nil
            }
            return RecipeEntity(recipe)
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [RecipeEntity] {
        let recipes = try modelContainer.mainContext.fetch(
            .recipes(.nameContains(string))
        )
        return recipes.compactMap(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipeEntity] {
        let recipes = try modelContainer.mainContext.fetch(
            .recipes(.all)
        )
        return recipes.compactMap(RecipeEntity.init)
    }
}
