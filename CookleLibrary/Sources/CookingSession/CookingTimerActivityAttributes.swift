#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

/// The Live Activity contract shared by the app and the Widgets extension.
///
/// One activity represents one cooking session's timer. The static
/// attributes identify the session and recipe; the content state carries the
/// countdown dates and step position.
public struct CookingTimerActivityAttributes: ActivityAttributes {
    public typealias ContentState = CookingTimerActivityState

    /// Identifies the cooking session that owns the activity.
    public let sessionKey: String
    /// The stable identifier of the recipe being cooked.
    public let recipeID: String
    /// The recipe name shown by the activity.
    public let recipeName: String

    public init(
        sessionKey: String,
        recipeID: String,
        recipeName: String
    ) {
        self.sessionKey = sessionKey
        self.recipeID = recipeID
        self.recipeName = recipeName
    }
}
#endif
