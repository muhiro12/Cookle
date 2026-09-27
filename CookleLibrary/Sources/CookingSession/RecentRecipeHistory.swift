import Foundation

/// The most-recently-opened recipe identifiers kept on iPhone.
///
/// Opening a recipe moves it to the front without duplicating it. The list is
/// a regenerable cache; losing it only empties the Watch's recent recipes.
public struct RecentRecipeHistory: Equatable, Sendable {
    /// Extra identifiers retained so deleted or step-less recipes can be
    /// skipped while still filling the catalog.
    public static let maximumStoredCount = RecentRecipeCatalog.maximumRecipeCount * storageMultiplier

    private static let storageMultiplier = 2

    public private(set) var recipeIDs: [String]

    public init(
        recipeIDs: [String] = []
    ) {
        self.recipeIDs = Array(
            Self.deduplicated(recipeIDs).prefix(Self.maximumStoredCount)
        )
    }

    private static func deduplicated(
        _ recipeIDs: [String]
    ) -> [String] {
        var seen = Set<String>()
        return recipeIDs.filter { seen.insert($0).inserted }
    }

    /// Moves a recipe to the front of the history.
    public mutating func recordOpened(
        _ recipeID: String
    ) {
        recipeIDs.removeAll { $0 == recipeID }
        recipeIDs.insert(recipeID, at: .zero)
        recipeIDs = Array(recipeIDs.prefix(Self.maximumStoredCount))
    }

    /// Drops identifiers that no longer resolve to recipes.
    public mutating func retainOnly(
        _ availableRecipeIDs: Set<String>
    ) {
        recipeIDs.removeAll { availableRecipeIDs.contains($0) == false }
    }
}
