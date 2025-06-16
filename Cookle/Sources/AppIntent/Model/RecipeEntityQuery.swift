import AppIntents
import SwiftData

struct RecipeEntityQuery: EntityStringQuery {
    func entities(for identifiers: [RecipeEntity.ID]) throws -> [RecipeEntity] {
        try identifiers.compactMap { id in
            guard let pid = try? PersistentIdentifier(base64Encoded: id),
                  let recipe = try CookleIntents.context.fetchFirst(.recipes(.idIs(pid))) else {
                return nil
            }
            return RecipeEntity(recipe)
        }
    }

    func entities(matching string: String) throws -> [RecipeEntity] {
        try CookleIntents.context.fetch(
            .recipes(.nameContains(string))
        ).compactMap(RecipeEntity.init)
    }

    func suggestedEntities() throws -> [RecipeEntity] {
        try CookleIntents.context.fetch(
            .recipes(.all)
        ).compactMap(RecipeEntity.init)
    }
}
