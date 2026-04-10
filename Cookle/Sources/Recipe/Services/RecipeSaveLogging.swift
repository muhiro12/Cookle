import CookleLibrary
import MHPlatform
import SwiftData

@MainActor
enum RecipeSaveLogging {
    struct Summary: Equatable {
        let operation: String
        let createdIngredientValues: [String]
        let reusedIngredientValues: [String]
        let createdCategoryValues: [String]
        let reusedCategoryValues: [String]

        var metadata: [String: String] {
            [
                "operation": operation,
                "ingredient_created_count": createdIngredientValues.count.description,
                "ingredient_reused_count": reusedIngredientValues.count.description,
                "ingredient_created_values": createdIngredientValues.joined(separator: "|"),
                "ingredient_reused_values": reusedIngredientValues.joined(separator: "|"),
                "category_created_count": createdCategoryValues.count.description,
                "category_reused_count": reusedCategoryValues.count.description,
                "category_created_values": createdCategoryValues.joined(separator: "|"),
                "category_reused_values": reusedCategoryValues.joined(separator: "|")
            ]
        }
    }

    static func makeSummary(
        operation: String,
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> Summary {
        .init(
            operation: operation,
            createdIngredientValues: createdIngredientValues(
                context: context,
                draft: draft
            ),
            reusedIngredientValues: reusedIngredientValues(
                context: context,
                draft: draft
            ),
            createdCategoryValues: createdCategoryValues(
                context: context,
                draft: draft
            ),
            reusedCategoryValues: reusedCategoryValues(
                context: context,
                draft: draft
            )
        )
    }

    static func logSuccess(
        logger: MHLogger,
        summary: Summary
    ) {
        logger.notice(
            "recipe save completed",
            metadata: summary.metadata
        )
    }

    static func logFailure(
        logger: MHLogger,
        summary: Summary,
        error: Error
    ) {
        var metadata = summary.metadata
        metadata["error_type"] = String(
            describing: type(of: error)
        )
        metadata["error"] = error.localizedDescription
        logger.error(
            "recipe save failed",
            metadata: metadata
        )
    }
}

private extension RecipeSaveLogging {
    static func createdIngredientValues(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> [String] {
        orderedUniqueValues(
            in: draft.ingredients.map(\.ingredient)
        )
        .filter { ingredientValue in
            ingredientExists(
                context: context,
                value: ingredientValue
            ) == false
        }
    }

    static func reusedIngredientValues(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> [String] {
        orderedUniqueValues(
            in: draft.ingredients.map(\.ingredient)
        )
        .filter { ingredientValue in
            ingredientExists(
                context: context,
                value: ingredientValue
            )
        }
    }

    static func createdCategoryValues(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> [String] {
        orderedUniqueValues(
            in: draft.categories
        )
        .filter { categoryValue in
            categoryExists(
                context: context,
                value: categoryValue
            ) == false
        }
    }

    static func reusedCategoryValues(
        context: ModelContext,
        draft: RecipeFormDraft
    ) -> [String] {
        orderedUniqueValues(
            in: draft.categories
        )
        .filter { categoryValue in
            categoryExists(
                context: context,
                value: categoryValue
            )
        }
    }

    static func orderedUniqueValues(
        in values: [String]
    ) -> [String] {
        var seenValues = Set<String>()

        return values.filter { value in
            guard seenValues.contains(value) == false else {
                return false
            }
            seenValues.insert(value)
            return true
        }
    }

    static func ingredientExists(
        context: ModelContext,
        value: String
    ) -> Bool {
        (try? context.fetchFirst(
            .ingredients(
                .valueIs(value)
            )
        )) != nil
    }

    static func categoryExists(
        context: ModelContext,
        value: String
    ) -> Bool {
        (try? context.fetchFirst(
            .categories(
                .valueIs(value)
            )
        )) != nil
    }
}
