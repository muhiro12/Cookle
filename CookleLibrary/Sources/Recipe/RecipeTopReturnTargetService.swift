import Foundation
import SwiftData

/// Internal quick-return target collaborator used by recipe Operations.
@preconcurrency
@MainActor
enum RecipeTopReturnTargetService {
    /// Returns the active cooking session target when valid, otherwise the last opened recipe target.
    static func target(
        context: ModelContext,
        activeCookingSessionSnapshot: String? = CooklePreferences.string(for: \.activeCookingSessionSnapshot),
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(for: \.lastOpenedRecipeID)
    ) throws -> RecipeTopReturnTarget? {
        if let activeTarget = activeCookingSessionTarget(
            activeCookingSessionSnapshot: activeCookingSessionSnapshot
        ) {
            return activeTarget
        }

        guard let lastOpenedRecipeID,
              let recipe = try RecipeService.lastOpenedRecipe(
                context: context,
                lastOpenedRecipeID: lastOpenedRecipeID
              ) else {
            return nil
        }

        return .init(
            kind: .lastOpenedRecipe,
            recipeName: recipe.name,
            recipeStableIdentifier: lastOpenedRecipeID
        )
    }
}

private extension RecipeTopReturnTargetService {
    static func activeCookingSessionTarget(
        activeCookingSessionSnapshot: String?
    ) -> RecipeTopReturnTarget? {
        guard let activeCookingSessionSnapshot,
              let snapshot = CookingSessionSnapshot.decoded(
                from: activeCookingSessionSnapshot
              ),
              snapshot.isActive,
              snapshot.steps.isEmpty == false else {
            return nil
        }

        return .init(
            kind: .activeCookingSession,
            recipeName: snapshot.recipeName,
            recipeStableIdentifier: snapshot.recipeID
        )
    }
}
