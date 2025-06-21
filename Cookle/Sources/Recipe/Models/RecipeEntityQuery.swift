import AppIntents
import SwiftData

struct RecipeEntityQuery: EntityStringQuery {
    @Dependency(\.modelContainer) private var modelContainer
    @MainActor
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

    @MainActor
    func entities(matching string: String) throws -> [RecipeEntity] {
        try modelContainer.mainContext.fetch(
            .recipes(.nameContains(string))
        ).compactMap(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipeEntity] {
        try modelContainer.mainContext.fetch(
            .recipes(.all)
        ).compactMap(RecipeEntity.init)
    }
}
