import SwiftData

/// Recipe use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum RecipeOperations {
    /// Returns the last opened recipe stored in preferences, if available.
    public static func lastOpenedRecipe(context: ModelContext) throws -> Recipe? {
        try RecipeService.lastOpenedRecipe(context: context)
    }

    /// Returns any single recipe from the store.
    public static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try RecipeService.randomRecipe(context: context)
    }

    /// Returns the most recently updated recipe.
    public static func latestRecipe(context: ModelContext) throws -> Recipe? {
        try RecipeService.latestRecipe(context: context)
    }

    /// Orders already-loaded recipes using the repository's canonical browse semantics.
    public static func browse(
        _ recipes: [Recipe],
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) -> [Recipe] {
        RecipeService.browse(
            recipes,
            sortMode: sortMode,
            isAscending: isAscending
        )
    }

    /// Searches and sorts recipes using the repository's canonical browse semantics.
    public static func search(
        context: ModelContext,
        criteria: RecipeBrowseCriteria
    ) throws -> [Recipe] {
        try RecipeService.search(
            context: context,
            criteria: criteria
        )
    }

    /// Searches recipes by a unified text condition that matches name, ingredients, or categories.
    public static func search(
        context: ModelContext,
        text: String
    ) throws -> [Recipe] {
        try RecipeService.search(
            context: context,
            text: text
        )
    }

    /// Deletes the supplied recipe and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        recipe: Recipe
    ) -> MutationOutcome<Void> {
        RecipeService.deleteWithOutcome(
            context: context,
            recipe: recipe
        )
    }

    /// Removes one persisted photo row from a recipe and returns follow-up hints.
    public static func removePhotoWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        photoObject: PhotoObject
    ) -> MutationOutcome<Void> {
        RecipeService.removePhotoWithOutcome(
            context: context,
            recipe: recipe,
            photoObject: photoObject
        )
    }

    /// Stores the current recipe as the last opened target and returns follow-up hints.
    public static func recordLastOpenedRecipeWithOutcome(
        _ recipe: Recipe
    ) -> MutationOutcome<Void> {
        RecipeService.recordLastOpenedRecipeWithOutcome(recipe)
    }
}
