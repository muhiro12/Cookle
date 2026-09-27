import Foundation

/// A recently opened recipe prepared for cooking on a paired Watch.
///
/// This is regenerable cached content, not a live mirror of the recipe.
public struct RecentRecipe: Codable, Equatable, Identifiable, Sendable {
    /// The stable recipe identifier used by cooking sessions.
    public let recipeID: String
    public let title: String
    public let steps: [String]
    /// The recipe's modification date when this entry was prepared.
    public let updatedAt: Date

    public var id: String {
        recipeID
    }

    public init(
        recipeID: String,
        title: String,
        steps: [String],
        updatedAt: Date
    ) {
        self.recipeID = recipeID
        self.title = title
        self.steps = steps
        self.updatedAt = updatedAt
    }

    /// Returns a fresh cooking snapshot for this recipe. Viewing a recipe never
    /// starts cooking; callers use this only for an explicit start.
    public func startingSnapshot(
        startedAt: Date = .now
    ) -> CookingSessionSnapshot {
        .init(
            recipeID: recipeID,
            recipeName: title,
            steps: steps,
            currentStepIndex: .zero,
            activeTimer: nil,
            updatedAt: startedAt,
            isActive: true
        )
    }
}
