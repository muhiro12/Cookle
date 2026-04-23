import Foundation

/// Stores lightweight favorite recipe selections outside the SwiftData schema.
public enum FavoriteRecipeService {
    /// Returns favorite recipe identifiers from the encoded preference payload.
    public static func favoriteRecipeIdentifiers(
        from encodedFavoriteRecipeIDs: String?
    ) -> Set<String> {
        guard let encodedFavoriteRecipeIDs,
              encodedFavoriteRecipeIDs.isEmpty == false,
              let data = encodedFavoriteRecipeIDs.data(using: .utf8),
              let identifiers = try? decoder.decode(
                [String].self,
                from: data
              ) else {
            return []
        }

        return .init(identifiers)
    }

    /// Encodes favorite recipe identifiers as a deterministic preference payload.
    public static func encodedFavoriteRecipeIDs(
        _ favoriteRecipeIdentifiers: Set<String>
    ) -> String? {
        let sortedIdentifiers = favoriteRecipeIdentifiers.sorted()
        guard sortedIdentifiers.isEmpty == false,
              let data = try? encoder.encode(sortedIdentifiers) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Returns whether the supplied recipe is currently marked as favorite.
    public static func isFavorite(
        _ recipe: Recipe,
        encodedFavoriteRecipeIDs: String?
    ) -> Bool {
        favoriteRecipeIdentifiers(
            from: encodedFavoriteRecipeIDs
        )
        .contains(
            RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            )
        )
    }

    /// Filters an already-loaded recipe collection to favorite recipes only.
    public static func favoriteRecipes(
        _ recipes: [Recipe],
        encodedFavoriteRecipeIDs: String?
    ) -> [Recipe] {
        let identifiers = favoriteRecipeIdentifiers(
            from: encodedFavoriteRecipeIDs
        )
        return recipes.filter { recipe in
            identifiers.contains(
                RecipeStableIdentifierCodec.stableIdentifier(
                    for: recipe
                )
            )
        }
    }

    /// Filters an already-loaded recipe collection to non-favorite recipes only.
    public static func nonFavoriteRecipes(
        _ recipes: [Recipe],
        encodedFavoriteRecipeIDs: String?
    ) -> [Recipe] {
        let identifiers = favoriteRecipeIdentifiers(
            from: encodedFavoriteRecipeIDs
        )
        return recipes.filter { recipe in
            identifiers.contains(
                RecipeStableIdentifierCodec.stableIdentifier(
                    for: recipe
                )
            ) == false
        }
    }

    /// Returns an updated encoded preference payload after applying the favorite state.
    public static func setFavorite(
        _ isFavorite: Bool,
        recipe: Recipe,
        encodedFavoriteRecipeIDs: String?
    ) -> String? {
        var identifiers = favoriteRecipeIdentifiers(
            from: encodedFavoriteRecipeIDs
        )
        let identifier = RecipeStableIdentifierCodec.stableIdentifier(
            for: recipe
        )

        if isFavorite {
            identifiers.insert(identifier)
        } else {
            identifiers.remove(identifier)
        }

        return Self.encodedFavoriteRecipeIDs(
            identifiers
        )
    }
}

private extension FavoriteRecipeService {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static var decoder: JSONDecoder {
        .init()
    }
}
