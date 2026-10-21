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
    /// Payload kind identifying recipe suggestions independently of request IDs.
    public static let recipeSuggestionContentKind = "recipeSuggestion"
    /// Payload kind identifying timers independently of request IDs.
    public static let cookingTimerContentKind = "cookingTimer"

    /// Whether the request belongs to suggestion synchronization or cleanup.
    public static func isManagedSuggestion(
        identifier: String,
        contentKind: String?
    ) -> Bool {
        identifier.hasPrefix(suggestionIdentifierPrefix)
            || identifier == testSuggestionIdentifier
            || contentKind == recipeSuggestionContentKind
    }

    /// Whether meal-usage suppression applies to a scheduled suggestion.
    public static func isScheduledSuggestionIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(suggestionIdentifierPrefix)
    }

    /// Whether the request belongs to timer reconciliation.
    public static func isCookingTimer(
        identifier: String,
        contentKind: String?
    ) -> Bool {
        identifier == cookingTimerIdentifier || contentKind == cookingTimerContentKind
    }

    /// Classifies a pending timer for the delivery planner.
    ///
    /// An empty key marks an obsolete or malformed request. Unlike `nil`, it
    /// makes the planner cancel the request before scheduling its replacement.
    public static func pendingCookingTimerKey(
        identifier: String,
        contentKind: String?,
        timerKey: String?
    ) -> String? {
        guard isCookingTimer(identifier: identifier, contentKind: contentKind) else {
            return nil
        }
        if identifier != cookingTimerIdentifier {
            return ""
        }
        return timerKey ?? ""
    }
}
