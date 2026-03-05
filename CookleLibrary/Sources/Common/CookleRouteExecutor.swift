import Foundation
import SwiftData

/// Resolves a `CookleRoute` into a navigation outcome for the main UI.
@preconcurrency
@MainActor
public enum CookleRouteExecutor {
    private static let noonHour = Int("12") ?? .zero

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
        case let .diaryDate(year, month, day):
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
        case let .recipeDetail(recipeID):
            guard let persistentIdentifier = try? PersistentIdentifier(
                base64Encoded: recipeID
            ) else {
                return .recipe(recipe: nil)
            }
            let recipe = try context.fetchFirst(
                .recipes(.idIs(persistentIdentifier))
            )
            return .recipe(recipe: recipe)
        case let .search(query):
            return .search(query: query)
        case .settings,
             .settingsSubscription,
             .settingsLicense:
            return settingsOutcome(for: route)
        }
    }

    private static func settingsOutcome(for route: CookleRoute) -> CookleRouteOutcome {
        switch route {
        case .settings:
            return .settings
        case .settingsSubscription:
            return .settingsSubscription
        case .settingsLicense:
            return .settingsLicense
        default:
            return .home
        }
    }

    private static func resolveDate(
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
            hour: noonHour,
            minute: 0,
            second: 0
        )
        return calendar.date(from: dateComponents)
    }
}
