import Foundation
import SwiftData

/// Resolves a `CookleRoute` into a navigation outcome for the main UI.
@preconcurrency
@MainActor
public enum CookleRouteExecutor {
    /// Resolves a route into the navigation outcome the app should present.
    public static func execute(
        route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
        case .home:
            return .home
        case .diary:
            return .diary(diary: nil)
        case .diaryDate(let year, let month, let day):
            guard let targetDate = resolveDate(
                year: year,
                month: month,
                day: day
            ) else {
                return .diary(diary: nil)
            }
            let diary = try DiaryService.diary(
                on: targetDate,
                context: context
            )
            return .diary(diary: diary)
        case .recipe:
            return .recipe(recipe: nil)
        case .recipeDetail(let recipeID):
            guard let persistentIdentifier = try? PersistentIdentifier(
                base64Encoded: recipeID
            ) else {
                return .recipe(recipe: nil)
            }
            let recipe = try context.fetchFirst(
                .recipes(.idIs(persistentIdentifier))
            )
            return .recipe(recipe: recipe)
        case .search(let query):
            return .search(query: query)
        case .settings:
            return .settings
        case .settingsSubscription:
            return .settingsSubscription
        case .settingsLicense:
            return .settingsLicense
        }
    }
}

/// Describes the navigation target produced by `CookleRouteExecutor`.
public enum CookleRouteOutcome {
    /// Shows the home screen.
    case home
    /// Shows the diary flow, optionally focusing an existing diary.
    case diary(diary: Diary?)
    /// Shows the recipe flow, optionally focusing an existing recipe.
    case recipe(recipe: Recipe?)
    /// Shows the search screen with an optional query.
    case search(query: String?)
    /// Shows the settings root screen.
    case settings
    /// Shows the subscription settings screen.
    case settingsSubscription
    /// Shows the license settings screen.
    case settingsLicense
}

private extension CookleRouteExecutor {
    static func resolveDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let dateComponents = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: 12,
            minute: 0,
            second: 0
        )
        return calendar.date(from: dateComponents)
    }
}
