import Foundation

/// The bounded list of recently opened recipes sent from iPhone to Watch.
///
/// The phone is authoritative: an empty decoded catalog means there are no
/// usable recent recipes, while a missing or unreadable payload means the
/// Watch keeps its last accepted catalog.
public struct RecentRecipeCatalog: Codable, Equatable, Sendable {
    /// The format this build writes and understands.
    public static let supportedFormatVersion = 1
    /// The maximum number of recipes in a catalog.
    public static let maximumRecipeCount = 5
    /// The maximum encoded size, well below the application context budget so
    /// the cooking session state always fits beside it.
    public static let maximumEncodedByteCount = 24_000

    /// The format this catalog was written with.
    public let formatVersion: Int
    /// Recipes ordered most recently opened first.
    public let recipes: [RecentRecipe]
    /// When the phone prepared this catalog.
    public let generatedAt: Date

    public init(
        recipes: [RecentRecipe],
        generatedAt: Date
    ) {
        self.formatVersion = Self.supportedFormatVersion
        self.recipes = recipes
        self.generatedAt = generatedAt
    }

    /// Builds a catalog from recipes ordered most recent first.
    ///
    /// Duplicates and recipes without steps are skipped, the count is bounded,
    /// and a recipe that would push the encoded size over budget is omitted
    /// rather than truncated.
    public static func bounded(
        _ candidates: [RecentRecipe],
        generatedAt: Date
    ) -> Self {
        var seenRecipeIDs = Set<String>()
        var acceptedRecipes = [RecentRecipe]()
        for candidate in candidates {
            guard acceptedRecipes.count < maximumRecipeCount,
                  candidate.steps.isEmpty == false,
                  seenRecipeIDs.insert(candidate.recipeID).inserted else {
                continue
            }
            let trial = Self(
                recipes: acceptedRecipes + [candidate],
                generatedAt: generatedAt
            )
            guard let encoded = trial.encodedString(),
                  encoded.utf8.count <= maximumEncodedByteCount else {
                continue
            }
            acceptedRecipes.append(candidate)
        }
        return .init(
            recipes: acceptedRecipes,
            generatedAt: generatedAt
        )
    }

    /// Decodes a catalog, returning `nil` for malformed, unsupported, or
    /// oversized payloads so the receiver keeps its last accepted catalog.
    public static func decoded(
        from value: String
    ) -> Self? {
        guard value.utf8.count <= maximumEncodedByteCount,
              let data = value.data(using: .utf8),
              let catalog = try? JSONDecoder().decode(
                Self.self,
                from: data
              ),
              catalog.formatVersion == supportedFormatVersion,
              catalog.recipes.count <= maximumRecipeCount,
              Set(catalog.recipes.map(\.recipeID)).count == catalog.recipes.count,
              catalog.recipes.allSatisfy({ !$0.recipeID.isEmpty && !$0.steps.isEmpty }) else {
            return nil
        }
        return catalog
    }

    /// Encodes the catalog for transport or caching.
    public func encodedString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        return String(
            data: data,
            encoding: .utf8
        )
    }
}
