import Foundation
import SwiftData

/// Cooking session and Watch companion use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum CookingSessionOperations {
    /// Applies a received application context to local state.
    ///
    /// Missing, malformed, unsupported, and legacy-only payloads never clear
    /// local state. Returns the peer status the context implies, or `nil`
    /// when the context says nothing about compatibility.
    public static func applyReceivedContext(
        _ context: [String: Any],
        to state: inout CookingSessionLocalState
    ) -> (changed: Bool, peerStatus: CookingSessionPeerStatus?) {
        switch WatchCompanionContext.sessionPayload(in: context) {
        case .state(let incomingState):
            return (state.merge(incomingState), .compatible)
        case .legacyOnly:
            return (false, .peerRequiresUpdate)
        case .unsupported:
            return (false, .thisDeviceRequiresUpdate)
        case .absent,
             .malformed:
            return (false, nil)
        }
    }

    /// Builds the recent recipe catalog from stored identifiers, most recent
    /// first, and returns the identifiers that still resolve to recipes.
    ///
    /// Deleted recipes drop out of the history; recipes without steps stay in
    /// the history but are omitted from the catalog.
    public static func recentRecipeCatalog(
        history: RecentRecipeHistory,
        context: ModelContext,
        generatedAt: Date = .now
    ) throws -> (catalog: RecentRecipeCatalog, history: RecentRecipeHistory) {
        var candidates = [RecentRecipe]()
        var availableRecipeIDs = Set<String>()
        for recipeID in history.recipeIDs {
            guard let recipe = try RecipeStableIdentifierCodec.recipe(
                from: recipeID,
                context: context
            ) else {
                continue
            }
            availableRecipeIDs.insert(recipeID)
            candidates.append(
                recentRecipe(
                    for: recipe,
                    recipeID: recipeID
                )
            )
        }
        var updatedHistory = history
        updatedHistory.retainOnly(availableRecipeIDs)
        return (
            RecentRecipeCatalog.bounded(
                candidates,
                generatedAt: generatedAt
            ),
            updatedHistory
        )
    }

    /// Derives the timer alert from the current durable session state.
    public static func timerAlert(
        in state: CookingSessionLocalState
    ) -> CookingTimerAlert? {
        CookingTimerAlert.current(in: state)
    }

    /// Plans notification replacement and cancellation from current state.
    public static func timerNotificationChanges(
        for alert: CookingTimerAlert?,
        pendingTimerKey: String?,
        deliveredTimerKey: String?,
        isAuthorized: Bool,
        now: Date
    ) -> CookingTimerDeliveryPlan.NotificationChanges {
        CookingTimerDeliveryPlan.notificationChanges(
            for: alert,
            pendingTimerKey: pendingTimerKey,
            deliveredTimerKey: deliveredTimerKey,
            isAuthorized: isAuthorized,
            now: now
        )
    }

    /// Plans changes to the system's current cooking Live Activities.
    public static func timerActivityChanges(
        for alert: CookingTimerAlert?,
        existing activities: [CookingTimerDeliveryPlan.ActivityRecord],
        allowsRequest: Bool,
        now: Date
    ) -> [CookingTimerDeliveryPlan.ActivityChange] {
        CookingTimerDeliveryPlan.activityChanges(
            for: alert,
            existing: activities,
            allowsRequest: allowsRequest,
            now: now
        )
    }

    /// Returns the stable identifier cooking sessions use for a recipe.
    public static func recentRecipeID(
        for recipe: Recipe
    ) -> String {
        RecipeStableIdentifierCodec.stableIdentifier(for: recipe)
    }
}

private extension CookingSessionOperations {
    static func recentRecipe(
        for recipe: Recipe,
        recipeID: String
    ) -> RecentRecipe {
        .init(
            recipeID: recipeID,
            title: recipe.name,
            steps: recipe.steps,
            updatedAt: recipe.modifiedTimestamp
        )
    }
}
