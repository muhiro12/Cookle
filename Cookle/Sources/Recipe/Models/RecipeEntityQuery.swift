import AppIntents
import SwiftData

@MainActor
struct RecipeEntityQuery: EntityStringQuery {
    @Dependency private var modelContainer: ModelContainer

    func entities(for identifiers: [RecipeEntity.ID]) throws -> [RecipeEntity] {
        try identifiers.compactMap { id in
            let persistentIdentifier = try PersistentIdentifier(base64Encoded: id)
            guard let recipe = try modelContainer.mainContext.fetchFirst(
                .recipes(.idIs(persistentIdentifier))
            ) else {
                return nil
            }
            return RecipeEntity(recipe)
        }
    }

    func entities(matching string: String) throws -> [RecipeEntity] {
        try modelContainer.mainContext.fetch(
            .recipes(.nameContains(string))
        ).compactMap(RecipeEntity.init)
    }

    func suggestedEntities() throws -> [RecipeEntity] {
        try modelContainer.mainContext.fetch(
            .recipes(.all)
        ).compactMap(RecipeEntity.init)
    }
}
