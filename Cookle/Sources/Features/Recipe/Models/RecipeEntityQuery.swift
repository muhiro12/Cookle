import AppIntents
import SwiftData

struct RecipeEntityQuery: EntityStringQuery {
    // Picker candidates are bounded so a large collection cannot be loaded whole
    // into an App Intents process. Matches the Widgets query's existing limit.
    private static let suggestionLimit = 50

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [RecipeEntity.ID]) throws -> [RecipeEntity] {
        try identifiers.compactMap { id in
            let persistentIdentifier = try RecipeStableIdentifierCodec.decode(
                id
            )
            var descriptor = FetchDescriptor<Recipe>.recipes(
                .idIs(persistentIdentifier)
            )
            descriptor.fetchLimit = 1
            guard let recipe = try modelContainer.mainContext.fetch(descriptor).first else {
                return nil
            }
            return RecipeEntity(recipe)
        }
    }

    @MainActor
    func entities(matching string: String) throws -> [RecipeEntity] {
        var descriptor = FetchDescriptor<Recipe>.recipes(.nameContains(string))
        descriptor.fetchLimit = Self.suggestionLimit
        let recipes = try modelContainer.mainContext.fetch(descriptor)
        return recipes.compactMap(RecipeEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipeEntity] {
        var descriptor = FetchDescriptor<Recipe>.recipes(.all)
        descriptor.fetchLimit = Self.suggestionLimit
        let recipes = try modelContainer.mainContext.fetch(descriptor)
        return recipes.compactMap(RecipeEntity.init)
    }
}
