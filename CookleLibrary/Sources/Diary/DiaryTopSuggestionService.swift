import Foundation
import SwiftData

/// Builds the diary-list suggestion candidate from existing persisted state.
@preconcurrency
@MainActor
public enum DiaryTopSuggestionService {
    public static func suggestion(
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current,
        lastOpenedRecipeID: String? = CookleSharedPreferences.string(for: \.lastOpenedRecipeID)
    ) throws -> DiaryTopSuggestion? {
        let diaryDate = calendar.startOfDay(for: now)

        guard try DiaryService.diary(
            on: diaryDate,
            context: context
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

    public static func mealType(
        for date: Date,
        calendar: Calendar = .current
    ) -> DiaryObjectType {
        let hour = calendar.component(
            .hour,
            from: date
        )

        switch hour {
        case ..<11:
            return .breakfast
        case ..<16:
            return .lunch
        default:
            return .dinner
        }
    }
}
