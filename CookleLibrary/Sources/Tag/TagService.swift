import SwiftData

/// Shared tag workflows used by app targets and intents.
@preconcurrency
@MainActor
public enum TagService {
    /// Renames an ingredient tag.
    public static func rename(
        context _: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws {
        let normalizedValue = try normalized(value)
        ingredient.update(value: normalizedValue)
    }

    /// Renames a category tag.
    public static func rename(
        context _: ModelContext,
        category: Category,
        value: String
    ) throws {
        let normalizedValue = try normalized(value)
        category.update(value: normalizedValue)
    }

    /// Deletes an ingredient when it is not referenced by recipes.
    public static func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) throws {
        if ingredient.recipes.isNotEmpty {
            throw TagServiceError.ingredientInUse(ingredient.value)
        }
        context.delete(ingredient)
    }

    /// Deletes a category.
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
