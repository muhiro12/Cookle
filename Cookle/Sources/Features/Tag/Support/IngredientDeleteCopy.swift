import CookleLibrary
import Foundation

enum IngredientDeleteCopy {
    static func title(for review: TagDeletionReview<Ingredient>) -> String {
        String(localized: "Delete \(review.value)")
    }

    static func confirmationDialog(for review: TagDeletionReview<Ingredient>) -> String {
        "\(title(for: review))? \(message(for: review))"
    }

    static func message(for _: TagDeletionReview<Ingredient>) -> String {
        String(
            localized: "This removes the unused ingredient record. No recipe ingredient rows will be removed."
        )
    }

    static func inUseMessage(for review: TagDeletionReview<Ingredient>) -> String {
        let examples = ReviewExampleCopy.list(
            review.recipeNameExamples,
            totalCount: review.recipeCount
        )
        return inUseMessage(
            value: review.value,
            recipeCount: review.recipeCount
        ) + "\n\n" + String(localized: "Recipes: \(examples).")
    }

    static func inUseMessage(value: String, recipeCount: Int) -> String {
        if recipeCount == 1 {
            return String(
                localized: """
                Delete is available only when no recipes use this ingredient. \
                \(value) is still used by one recipe.
                """
            )
        }

        return String(
            localized: """
            Delete is available only when no recipes use this ingredient. \
            \(value) is still used by \(recipeCount) recipes.
            """
        )
    }

    static func rejectionDialog(for review: TagDeletionReview<Ingredient>) -> String {
        String(localized: "Cannot delete \(review.value).") + " " + inUseMessage(for: review)
    }

    static func successDialog(for review: TagDeletionReview<Ingredient>) -> String {
        String(localized: "Deleted \(review.value)")
    }
}
