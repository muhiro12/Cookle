import Foundation
import SwiftData

/// Internal recipe collaborator used by public Operations.
@preconcurrency
@MainActor
enum RecipeService {
    /// Returns the last opened recipe stored in preferences, if available.
    /// - Parameters:
    ///   - context: Model context to query.
    /// - Returns: The matching `Recipe` or `nil` when not found.
    static func lastOpenedRecipe(context: ModelContext) throws -> Recipe? {
        try lastOpenedRecipe(
            context: context,
            lastOpenedRecipeID: CookleSharedPreferences.string(for: \.lastOpenedRecipeID)
        )
    }

    /// Returns the last opened recipe stored in preferences, if available.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - lastOpenedRecipeID: Optional base64-encoded persistent identifier.
    /// - Returns: The matching `Recipe` or `nil` when not found.
    static func lastOpenedRecipe(
        context: ModelContext,
        lastOpenedRecipeID: String?
    ) throws -> Recipe? {
        guard let lastOpenedRecipeID else {
            return nil
        }
        return try RecipeStableIdentifierCodec.recipe(
            from: lastOpenedRecipeID,
            context: context
        )
    }

    /// Returns any single recipe from the store.
    /// - Parameter context: Model context to query.
    /// - Returns: A random `Recipe` or `nil` when the store is empty.
    static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try context.fetch(.recipes(.all)).randomElement()
    }

    /// Returns the most recently updated recipe.
    static func latestRecipe(context: ModelContext) throws -> Recipe? {
        let descriptor: FetchDescriptor<Recipe> = .init(
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse),
                .init(\.createdTimestamp, order: .reverse),
                .init(\.name)
            ]
        )
        return try context.fetch(descriptor).first
    }

    /// Orders already-loaded recipes using the repository's canonical browse semantics.
    /// - Parameters:
    ///   - recipes: In-memory recipes to order for a browse surface.
    ///   - sortMode: Sort mode to apply.
    ///   - isAscending: Sort direction.
    /// - Returns: The ordered recipes.
    static func browse(
        _ recipes: [Recipe],
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) -> [Recipe] {
        sortedRecipes(
            recipes,
            criteria: .init(
                searchText: "",
                sortMode: sortMode,
                isAscending: isAscending
            )
        )
    }

    /// Searches and sorts recipes using the repository's canonical browse semantics.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - criteria: Shared browse criteria including text search and sort mode.
    /// - Returns: Matching recipes ordered for the caller's browse surface.
    static func search(
        context: ModelContext,
        criteria: RecipeBrowseCriteria
    ) throws -> [Recipe] {
        let predicate: RecipePredicate = if criteria.searchText.isEmpty {
            .all
        } else {
            .anyTextMatches(criteria.searchText)
        }
        let recipes = try context.fetch(.recipes(predicate))
        return sortedRecipes(
            recipes,
            criteria: criteria
        )
    }

    /// Searches recipes by a unified text condition that matches name, ingredients, or categories.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text. Short text (< 3 chars) uses equality for tags; otherwise partial match.
    /// - Returns: Matching recipes ordered by name.
    static func search(context: ModelContext, text: String) throws -> [Recipe] {
        try search(
            context: context,
            criteria: .init(
                searchText: text,
                sortMode: .alphabetical,
                isAscending: true
            )
        )
    }

    /// Deletes the supplied recipe from the store.
    static func delete(
        context: ModelContext,
        recipe: Recipe
    ) {
        _ = deleteWithOutcome(
            context: context,
            recipe: recipe
        )
    }

    /// Deletes the supplied recipe and returns follow-up hints.
    static func deleteWithOutcome(
        context: ModelContext,
        recipe: Recipe
    ) -> MutationOutcome<Void> {
        context.delete(recipe)
        return .init(
            value: (),
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }

    /// Removes one persisted photo row from a recipe and returns follow-up hints.
    static func removePhotoWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        photoObject: PhotoObject
    ) -> MutationOutcome<Void> {
        let remainingPhotoObjects = (recipe.photoObjects ?? []).filter { currentPhotoObject in
            currentPhotoObject.persistentModelID != photoObject.persistentModelID
        }

        context.delete(photoObject)
        var content = recipe.content
        content.photos = remainingPhotoObjects
        recipe.update(content: content)

        return .init(
            value: (),
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }

    /// Stores the current recipe as the last opened target.
    static func recordLastOpenedRecipe(_ recipe: Recipe) {
        _ = recordLastOpenedRecipeWithOutcome(
            recipe
        )
    }

    /// Stores the current recipe as the last opened target and returns follow-up hints.
    static func recordLastOpenedRecipeWithOutcome(
        _ recipe: Recipe
    ) -> MutationOutcome<Void> {
        let encodedRecipeID = RecipeStableIdentifierCodec.encodeIfPossible(
            recipe.id
        )
        CookleSharedPreferences.set(
            encodedRecipeID,
            for: \.lastOpenedRecipeID
        )
        return .init(
            value: (),
            effects: [
                .recipeDataChanged
            ]
        )
    }
}

private extension RecipeService {
    static func sortedRecipes(
        _ recipes: [Recipe],
        criteria: RecipeBrowseCriteria
    ) -> [Recipe] {
        recipes.sorted { lhs, rhs in
            comesBefore(
                lhs,
                rhs,
                sortMode: criteria.sortMode,
                isAscending: criteria.isAscending
            )
        }
    }

    static func comesBefore(
        _ lhs: Recipe,
        _ rhs: Recipe,
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) -> Bool {
        switch sortMode {
        case .alphabetical:
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: isAscending
            )
        case .recentlyCreated:
            if lhs.createdTimestamp != rhs.createdTimestamp {
                return isAscending
                    ? lhs.createdTimestamp < rhs.createdTimestamp
                    : lhs.createdTimestamp > rhs.createdTimestamp
            }
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: true
            )
        case .madeCount:
            let lhsCount = (lhs.diaryObjects ?? []).count
            let rhsCount = (rhs.diaryObjects ?? []).count

            if lhsCount != rhsCount {
                return isAscending
                    ? lhsCount < rhsCount
                    : lhsCount > rhsCount
            }
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: true
            )
        }
    }

    static func compareNames(
        _ lhs: String,
        _ rhs: String,
        ascending: Bool
    ) -> Bool {
        let comparison = lhs.localizedStandardCompare(rhs)
        if comparison == .orderedSame {
            return false
        }
        if ascending {
            return comparison == .orderedAscending
        }
        return comparison == .orderedDescending
    }
}
