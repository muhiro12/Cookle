import SwiftData

/// How one conflicting imported recipe is applied.
public enum CookleDataRecipeImportChoice: Hashable, Sendable {
    /// Keeps the chosen current recipe unchanged; imported diaries that use
    /// this recipe show the current one.
    case keepCurrent(PersistentIdentifier)
    /// Replaces the chosen current recipe's content with the imported version,
    /// keeping the recipe itself so its diary rows show the new content.
    case useBackup(PersistentIdentifier)
    /// Adds the imported version as a separate recipe.
    case keepBoth
}
