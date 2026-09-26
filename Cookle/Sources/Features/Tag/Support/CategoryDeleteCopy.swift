import CookleLibrary
import Foundation

enum CategoryDeleteCopy {
    static func title(for review: TagDeletionReview<Category>) -> String {
        String(localized: "Delete \(review.value)")
    }

    static func confirmationDialog(for review: TagDeletionReview<Category>) -> String {
        "\(title(for: review))? \(message(for: review))"
    }

    static func message(for review: TagDeletionReview<Category>) -> String {
        let affectedRecipeCount = review.recipeCount

        if affectedRecipeCount == 0 {
            return String(
                localized: "This removes the category. No recipe relations will be removed."
            )
        }

        let impact: String
        if affectedRecipeCount == 1 {
            impact = String(
                localized: "This removes the category from one recipe. The recipe stays saved."
            )
        } else {
            impact = String(
                localized: """
                This removes the category from \(affectedRecipeCount) recipes. \
                The recipes stay saved.
                """
            )
        }

        let examples = ReviewExampleCopy.list(
            review.recipeNameExamples,
            totalCount: affectedRecipeCount
        )
        return impact + "\n\n" + String(localized: "Recipes: \(examples).")
    }

    static func successDialog(for review: TagDeletionReview<Category>) -> String {
        String(localized: "Deleted \(review.value)")
    }
}
