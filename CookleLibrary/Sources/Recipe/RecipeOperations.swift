import Foundation
import SwiftData

/// Recipe use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum RecipeOperations {
    /// Resolves every stable recipe identifier in input order.
    ///
    /// - Returns: Matching recipes.
    /// - Throws: `RecipeResolutionError.recipeNotFound` when any identifier is invalid or
    ///   missing, or a SwiftData fetch error when the lookup fails.
    public static func resolveRecipes(
        stableIdentifiers: [String],
        context: ModelContext
    ) throws -> [Recipe] {
        let recipes = try RecipeStableIdentifierCodec.recipes(
            from: stableIdentifiers,
            context: context
        )
        guard recipes.count == stableIdentifiers.count else {
            throw RecipeResolutionError.recipeNotFound
        }

        return recipes
    }

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

    /// Returns the highest-priority quick-return target for the recipe list.
    public static func topReturnTarget(
        context: ModelContext,
        activeCookingSessionSnapshot: String? = CooklePreferences.string(
            for: \.activeCookingSessionSnapshot
        ),
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(
            for: \.lastOpenedRecipeID
        )
    ) throws -> RecipeTopReturnTarget? {
        try RecipeTopReturnTargetService.target(
            context: context,
            activeCookingSessionSnapshot: activeCookingSessionSnapshot,
            lastOpenedRecipeID: lastOpenedRecipeID
        )
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

    /// Builds future daily suggestion entries from recipe suggestion candidates.
    nonisolated public static func buildDailySuggestions(
        candidates: [DailyRecipeSuggestionCandidate],
        hour: Int,
        minute: Int,
        now: Date = .now,
        calendar: Calendar = .current,
        daysAhead: Int = 14,
        identifierPrefix: String = "daily-recipe-suggestion-"
    ) -> [DailyRecipeSuggestion] {
        DailyRecipeSuggestionService.buildSuggestions(
            candidates: candidates,
            hour: hour,
            minute: minute,
            now: now,
            calendar: calendar,
            daysAhead: daysAhead,
            identifierPrefix: identifierPrefix
        )
    }

    /// Records a first independent open or a notification-driven use in one bounded value.
    nonisolated public static func recordSuggestionUsage(
        in state: AdaptiveRecipeSuggestionState,
        at date: Date,
        isNotificationResponse: Bool,
        calendar: Calendar = .current
    ) -> AdaptiveRecipeSuggestionState {
        AdaptiveSuggestionPolicy.recordingUsage(
            in: state,
            at: date,
            isNotificationResponse: isNotificationResponse,
            calendar: calendar
        )
    }

    /// Prunes old local observations and expires each accepted meal independently.
    nonisolated public static func reconciledSuggestionState(
        _ state: AdaptiveRecipeSuggestionState,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> AdaptiveRecipeSuggestionState {
        AdaptiveSuggestionPolicy.reconciled(state, now: now, calendar: calendar)
    }

    /// Builds at most one future suggestion per local day and learned meal.
    ///
    /// The horizon includes today, matching the existing fixed-time planner. Already
    /// used meals are suppressed today, and no request survives its meal's expiry.
    nonisolated public static func buildAdaptiveSuggestions(
        candidates: [DailyRecipeSuggestionCandidate],
        state: AdaptiveRecipeSuggestionState,
        now: Date = .now,
        calendar: Calendar = .current,
        daysAhead: Int = 14,
        identifierPrefix: String = "daily-recipe-suggestion-"
    ) -> [DailyRecipeSuggestion] {
        DailyRecipeSuggestionService.buildAdaptiveSuggestions(
            candidates: candidates,
            state: reconciledSuggestionState(state, now: now, calendar: calendar),
            now: now,
            calendar: calendar,
            daysAhead: daysAhead,
            identifierPrefix: identifierPrefix
        )
    }

    /// Returns at most one local, half-hour-rounded time for each supplied meal.
    ///
    /// Callers supply eligible first-open observations. Meal boundaries, observation
    /// expiry, and delivery dates are deliberately outside this calculation.
    nonisolated public static func mealSuggestionTimes(
        from firstOpenDates: [DiaryObjectType: Date],
        isEnabled: Bool,
        calendar: Calendar = .current
    ) -> [DiaryObjectType: DateComponents] {
        guard isEnabled else {
            return [:]
        }

        let intervalMinutes = 30
        return firstOpenDates.mapValues { firstOpenDate -> DateComponents in
            let time = DailySuggestionTimePolicy.components(
                from: firstOpenDate,
                calendar: calendar
            )
            return .init(
                hour: time.hour,
                minute: time.minute / intervalMinutes * intervalMinutes,
                second: .zero
            )
        }
    }

    /// Returns a concise deterministic blurb from recipe content.
    nonisolated public static func makeBlurb(
        request: RecipeBlurbRequest,
        maxLength: Int = 72
    ) -> String? {
        RecipeBlurbService.makeBlurb(
            request: request,
            maxLength: maxLength
        )
    }

    /// Returns normalized Image Playground concept input from recipe content.
    nonisolated public static func makeImageConceptDraft(
        request: RecipeImageConceptRequest
    ) -> RecipeImageConceptDraft? {
        RecipeImageConceptService.makeDraft(
            request: request
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

    /// Describes what deleting `recipe` removes, as values for a review.
    public static func deletionReview(
        for recipe: Recipe
    ) -> RecipeDeletionReview {
        RecipeService.deletionReview(
            for: recipe
        )
    }

    /// Re-resolves the reviewed recipe and describes what deleting it removes now.
    ///
    /// - Returns: `nil` when the recipe no longer exists.
    public static func currentDeletionReview(
        for review: RecipeDeletionReview,
        context: ModelContext
    ) throws -> RecipeDeletionReview? {
        try RecipeService.currentDeletionReview(
            for: review,
            context: context
        )
    }

    /// Deletes the reviewed recipe after re-resolving it, and returns follow-up hints.
    ///
    /// - Throws: `ReviewedMutationError.targetMissing` when the recipe is gone,
    ///   or `ReviewedMutationError.impactChanged` when the diary meal rows it
    ///   would remove differ from the review. Neither case changes the store.
    public static func deleteWithOutcome(
        context: ModelContext,
        reviewed review: RecipeDeletionReview
    ) throws -> MutationOutcome<Void> {
        try RecipeService.deleteWithOutcome(
            context: context,
            reviewed: review
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
