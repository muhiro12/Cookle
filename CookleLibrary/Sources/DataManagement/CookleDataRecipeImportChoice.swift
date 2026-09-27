import SwiftData

/// How one conflicting backup recipe is imported.
public enum CookleDataRecipeImportChoice: Hashable, Sendable {
    /// Keeps the chosen current recipe unchanged; backup diaries that use this
    /// recipe show the current one.
    case keepCurrent(PersistentIdentifier)
    /// Replaces the chosen current recipe's content with the backup version,
    /// keeping the recipe itself so its diary rows show the new content.
    case useBackup(PersistentIdentifier)
    /// Adds the backup version as a separate recipe.
    case keepBoth
}
