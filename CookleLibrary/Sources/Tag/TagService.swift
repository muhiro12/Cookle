import SwiftData

/// Tag workflows shared by the app, widgets, and App Intents.
@preconcurrency
@MainActor
public enum TagService {
    private static var tagMutationEffects: MutationEffect {
        [
            .notificationPlanChanged
        ]
    }

    /// Renames an ingredient after trimming whitespace and validating non-empty input.
    public static func rename(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws {
        _ = try renameWithOutcome(
            context: context,
            ingredient: ingredient,
            value: value
        )
    }

    /// Renames an ingredient and returns follow-up hints.
    public static func renameWithOutcome(
        context _: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws -> MutationOutcome<Void> {
        let normalizedValue = try normalized(value)
        ingredient.update(value: normalizedValue)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Renames a category after trimming whitespace and validating non-empty input.
    public static func rename(
        context: ModelContext,
        category: Category,
        value: String
    ) throws {
        _ = try renameWithOutcome(
            context: context,
            category: category,
            value: value
        )
    }

    /// Renames a category and returns follow-up hints.
    public static func renameWithOutcome(
        context _: ModelContext,
        category: Category,
        value: String
    ) throws -> MutationOutcome<Void> {
        let normalizedValue = try normalized(value)
        category.update(value: normalizedValue)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Deletes an ingredient only when no recipe still references it.
    public static func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) throws {
        _ = try deleteWithOutcome(
            context: context,
            ingredient: ingredient
        )
    }

    /// Deletes an ingredient and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        if ingredient.recipes.isNotEmpty {
            throw TagServiceError.ingredientInUse(ingredient.value)
        }
        context.delete(ingredient)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Deletes the supplied category from the current model context.
    public static func delete(
        context: ModelContext,
        category: Category
    ) {
        _ = deleteWithOutcome(
            context: context,
            category: category
        )
    }

    /// Deletes the supplied category and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        category: Category
    ) -> MutationOutcome<Void> {
        context.delete(category)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
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
