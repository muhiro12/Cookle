import CookleLibrary
import Foundation

enum RecipeDeleteCopy {
    static func title(for review: RecipeDeletionReview) -> String {
        String(localized: "Delete \(review.recipeName)")
    }

    static func confirmationDialog(for review: RecipeDeletionReview) -> String {
        "\(title(for: review))? \(message(for: review))"
    }

    static func message(for review: RecipeDeletionReview) -> String {
        let affectedMealRowCount = review.mealRowCount
        if affectedMealRowCount == 0 {
            return String(
                localized: "This removes the recipe. No diary meal rows will be removed."
            )
        }

        let impact: String
        if affectedMealRowCount == 1 {
            impact = String(
                localized: "This removes the recipe and one diary meal row. The related diary entry stays saved."
            )
        } else {
            impact = String(
                localized: """
                This removes the recipe and \(affectedMealRowCount) diary meal rows. \
                The related diary entries stay saved.
                """
            )
        }

        let examples = ReviewExampleCopy.list(
            review.mealRowExamples.map(mealRowText),
            totalCount: affectedMealRowCount
        )
        return impact + "\n\n" + String(localized: "Affected diary days: \(examples).")
    }

    static func successDialog(for review: RecipeDeletionReview) -> String {
        String(localized: "Deleted \(review.recipeName)")
    }
}

private extension RecipeDeleteCopy {
    static func mealRowText(
        _ mealRow: RecipeDeletionReview.MealRow
    ) -> String {
        let dateText = mealRow.date?.formatted(
            .dateTime.year().month().day()
        ) ?? String(localized: "No date")
        guard let mealTitle = mealRow.type.map(Self.mealTitle) else {
            return dateText
        }

        return String(localized: "\(dateText) (\(mealTitle))")
    }

    static func mealTitle(
        for type: DiaryObjectType
    ) -> String {
        switch type {
        case .breakfast:
            String(localized: "Breakfast")
        case .lunch:
            String(localized: "Lunch")
        case .dinner:
            String(localized: "Dinner")
        }
    }
}
