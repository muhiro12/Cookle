import AppIntents
import SwiftData

struct RecipeEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [RecipeEntity.ID]) throws -> [RecipeEntity] {
        try identifiers.compactMap { id in
            let persistentIdentifier = try PersistentIdentifier(base64Encoded: id)
            guard let recipe = try CookleIntents.context.fetchFirst(.recipes(.idIs(persistentIdentifier))) else {
                return nil
            }
            return RecipeEntity(recipe)
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [RecipeEntity] {
        try CookleIntents.context.fetch(
            .recipes(.nameContains(string))
        ).compactMap(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipeEntity] {
        try CookleIntents.context.fetch(
            .recipes(.all)
        ).compactMap(RecipeEntity.init)
    }
}
