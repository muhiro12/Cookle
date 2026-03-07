import SwiftData

/// Tag workflows shared by the app, widgets, and App Intents.
@preconcurrency
@MainActor
public enum TagService {
    /// Renames an ingredient after trimming whitespace and validating non-empty input.
    public static func rename(
        context _: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws {
        let normalizedValue = try normalized(value)
        ingredient.update(value: normalizedValue)
    }

    /// Renames a category after trimming whitespace and validating non-empty input.
    public static func rename(
        context _: ModelContext,
        category: Category,
        value: String
    ) throws {
        let normalizedValue = try normalized(value)
        category.update(value: normalizedValue)
    }

    /// Deletes an ingredient only when no recipe still references it.
    public static func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) throws {
        if ingredient.recipes.isNotEmpty {
            throw TagServiceError.ingredientInUse(ingredient.value)
        }
        context.delete(ingredient)
    }

    /// Deletes the supplied category from the current model context.
    public static func delete(
        context: ModelContext,
        category: Category
    ) {
        context.delete(category)
    }

    private static func normalized(_ value: String) throws -> String {
        let normalizedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalizedValue.isNotEmpty else {
            throw TagServiceError.emptyValue
        }
        return normalizedValue
    }
}
