import SwiftData

enum DiaryIntentSupport {
    @MainActor
    static func resolveRecipes(
        from entities: Set<RecipeEntity>,
        context: ModelContext
    ) throws -> [Recipe] {
        let recipes: [Recipe]
        do {
            recipes = try RecipeOperations.resolveRecipes(
                stableIdentifiers: entities.map(\.id),
                context: context
            )
        } catch RecipeResolutionError.recipeNotFound {
            throw RecipeMutationIntentError.recipeNotFound
        }

        return recipes.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
