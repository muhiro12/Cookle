import Foundation
import SwiftData

/// Internal top-suggestion collaborator used by diary Operations.
@preconcurrency
@MainActor
enum DiaryTopSuggestionService {
    private enum MealHourBoundary {
        static let breakfastEndsAt = 11
        static let lunchEndsAt = 16
    }

    /// Returns a top-of-list diary suggestion for today when one can be derived.
    static func suggestion(
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current,
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(for: \.lastOpenedRecipeID)
    ) throws -> DiaryTopSuggestion? {
        let diaryDate = calendar.startOfDay(for: now)

        guard try DiaryService.diary(
            on: diaryDate,
            context: context,
            calendar: calendar
        ) == nil else {
            return nil
        }

        guard let recipe = try RecipeService.lastOpenedRecipe(
            context: context,
            lastOpenedRecipeID: lastOpenedRecipeID
        ) else {
            return nil
        }

        return .init(
            date: diaryDate,
            recipeName: recipe.name,
            recipeStableIdentifier: RecipeStableIdentifierCodec.stableIdentifier(
                for: recipe
            ),
            mealType: mealType(
                for: now,
                calendar: calendar
            )
        )
    }

    /// Resolves the meal bucket for a given date using the v1 fixed time boundaries.
    nonisolated static func mealType(
        for date: Date,
        calendar: Calendar = .current
    ) -> DiaryObjectType {
        let hour = calendar.component(
            .hour,
            from: date
        )

        switch hour {
        case ..<MealHourBoundary.breakfastEndsAt:
            return .breakfast
        case ..<MealHourBoundary.lunchEndsAt:
            return .lunch
        default:
            return .dinner
        }
    }
}
