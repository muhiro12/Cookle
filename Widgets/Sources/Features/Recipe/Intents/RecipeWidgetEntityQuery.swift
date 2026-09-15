import AppIntents
import CookleLibrary
import SwiftData

struct RecipeWidgetEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 50

    @MainActor
    func entities(for identifiers: [String]) throws -> [RecipeWidgetEntity] {
        let persistentIdentifiers = identifiers.compactMap { identifier in
            try? RecipeStableIdentifierCodec.decode(identifier)
        }
        guard !persistentIdentifiers.isEmpty else {
            return []
        }
        var descriptor = FetchDescriptor<Recipe>.recipes(.all)
        descriptor.predicate = #Predicate { recipe in
            persistentIdentifiers.contains(recipe.persistentModelID)
        }
        let context = try ModelContainerFactory.sharedContext()
        return try context.fetch(descriptor).compactMap(Self.entity)
    }

    @MainActor
    func entities(matching string: String) throws -> [RecipeWidgetEntity] {
        var descriptor = FetchDescriptor<Recipe>.recipes(.nameContains(string))
        descriptor.fetchLimit = Self.suggestionLimit
        let context = try ModelContainerFactory.sharedContext()
        return try context.fetch(descriptor).compactMap(Self.entity)
    }

    @MainActor
    func suggestedEntities() throws -> [RecipeWidgetEntity] {
        var descriptor = FetchDescriptor<Recipe>.recipes(.all)
        descriptor.fetchLimit = Self.suggestionLimit
        let context = try ModelContainerFactory.sharedContext()
        return try context.fetch(descriptor).compactMap(Self.entity)
    }
}

private extension RecipeWidgetEntityQuery {
    @MainActor
    static func entity(_ recipe: Recipe) -> RecipeWidgetEntity? {
        guard let identifier = RecipeStableIdentifierCodec.encodeIfPossible(recipe.id) else {
            return nil
        }
        return .init(id: identifier, name: recipe.name)
    }
}
