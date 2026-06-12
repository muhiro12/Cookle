import SwiftData

/// Tag use cases called by delivery surfaces.
@preconcurrency
@MainActor
public enum TagOperations {
    /// Renames an ingredient and returns follow-up hints.
    public static func renameWithOutcome(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws -> MutationOutcome<Void> {
        try TagService.renameWithOutcome(
            context: context,
            ingredient: ingredient,
            value: value
        )
    }

    /// Renames a category and returns follow-up hints.
    public static func renameWithOutcome(
        context: ModelContext,
        category: Category,
        value: String
    ) throws -> MutationOutcome<Void> {
        try TagService.renameWithOutcome(
            context: context,
            category: category,
            value: value
        )
    }

    /// Deletes a category and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        category: Category
    ) -> MutationOutcome<Void> {
        TagService.deleteWithOutcome(
            context: context,
            category: category
        )
    }

    /// Deletes an unused ingredient and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        try TagService.deleteWithOutcome(
            context: context,
            ingredient: ingredient
        )
    }

    /// Returns all tags that look equivalent to `tag` in the supplied collection.
    public static func duplicateTags<T: Tag>(
        matching tag: T,
        in tags: [T]
    ) -> [T] {
        TagService.duplicateTags(
            matching: tag,
            in: tags
        )
    }

    /// Returns one representative per duplicate-looking group in the supplied collection.
    public static func duplicateTags<T: Tag>(
        in tags: [T]
    ) -> [T] {
        TagService.duplicateTags(in: tags)
    }

    /// Merges duplicate-looking ingredients into the supplied ingredient.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: ingredient
        )
    }

    /// Merges duplicate-looking categories into the supplied category.
    public static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping category: Category
    ) throws -> MutationOutcome<Void> {
        try TagService.mergeDuplicatesWithOutcome(
            context: context,
            keeping: category
        )
    }
}
