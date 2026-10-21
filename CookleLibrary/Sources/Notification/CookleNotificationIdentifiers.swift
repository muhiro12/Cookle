import Foundation

/// Identifiers shared by notification producers and response adapters.
public enum CookleNotificationIdentifiers {
    /// Prefix separating the suggestion name from its occurrence identifier.
    public static let suggestionIdentifierPrefix = "dailyRecipeSuggestion."
    /// Request identifier for the Settings preview notification.
    public static let testSuggestionIdentifier = "dailyRecipeSuggestionTest"
    /// Request and thread identifier for the active cooking timer.
    public static let cookingTimerIdentifier = "cookingTimer"
    /// Thread grouping recipe suggestions.
    public static let suggestionThreadIdentifier = "dailyRecipeSuggestion"
    /// Category used by new recipe suggestions.
    public static let suggestionCategoryIdentifier = "dailyRecipeSuggestion"
    /// Action that opens the recipe browser.
    public static let browseRecipesActionIdentifier = "browseRecipes"

    /// Category retained for notifications delivered before normalization.
    public static let legacySuggestionCategoryIdentifier = "daily_recipe_suggestion"
    /// Action retained for notifications delivered before normalization.
    public static let legacyBrowseRecipesActionIdentifier = "browse_recipes"
    /// Timer identifier retained for cancellation and delivered alerts.
    public static let legacyCookingTimerIdentifier = "cooking-timer"

    private static let legacySuggestionIdentifierPrefix = "daily-recipe-suggestion-"
    private static let legacyTestSuggestionIdentifier = "daily-recipe-suggestion-test"

    /// Timer identifiers that cancellation must remove together.
    public static var cookingTimerIdentifiers: [String] {
        [cookingTimerIdentifier, legacyCookingTimerIdentifier]
    }

    /// Whether the request belongs to suggestion synchronization or cleanup.
    public static func isManagedSuggestionIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(suggestionIdentifierPrefix)
            || identifier.hasPrefix(legacySuggestionIdentifierPrefix)
            || identifier == testSuggestionIdentifier
    }

    /// Whether meal-usage suppression applies, excluding both preview versions.
    public static func isScheduledSuggestionIdentifier(_ identifier: String) -> Bool {
        isManagedSuggestionIdentifier(identifier)
            && identifier != testSuggestionIdentifier
            && identifier != legacyTestSuggestionIdentifier
    }

    /// Whether a response opens the recipe browser, including delivered alerts.
    public static func isBrowseRecipesAction(_ identifier: String) -> Bool {
        identifier == browseRecipesActionIdentifier
            || identifier == legacyBrowseRecipesActionIdentifier
    }

    /// Whether the request is a current or previously registered timer.
    public static func isCookingTimerIdentifier(_ identifier: String) -> Bool {
        cookingTimerIdentifiers.contains(identifier)
    }

    /// Classifies a pending timer for the delivery planner.
    ///
    /// An empty key marks an obsolete or malformed request. Unlike `nil`, it
    /// makes the planner cancel the request before scheduling its replacement.
    public static func pendingCookingTimerKey(
        identifier: String,
        timerKey: String?
    ) -> String? {
        guard isCookingTimerIdentifier(identifier) else {
            return nil
        }
        if identifier == legacyCookingTimerIdentifier {
            return ""
        }
        return timerKey ?? ""
    }
}
