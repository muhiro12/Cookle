import Foundation
import SwiftData

/// Resolves a `CookleRoute` into a navigation outcome for the main UI.
@preconcurrency
@MainActor
public enum CookleRouteExecutor {
    private static let noonHour = 12

    /// Resolves a route into the navigation outcome the app should present.
    public static func execute(
        route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
        case .home:
            return .home
        case .diary,
             .diaryDate:
            return try diaryOutcome(
                for: route,
                context: context
            )
        case .recipe,
             .recipeDetail:
            return try recipeOutcome(
                for: route,
                context: context
            )
        case .photo,
             .photoDetail:
            return try photoOutcome(
                for: route,
                context: context
            )
        case .tag,
             .tagDetail:
            return try tagOutcome(
                for: route,
                context: context
            )
        case let .search(query):
            return .search(query: query)
        case .settings,
             .settingsSubscription,
             .settingsLicense:
            return settingsOutcome(for: route)
        }
    }

    private static func diaryOutcome(
        for route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
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
        default:
            return .home
        }
    }

    private static func recipeOutcome(
        for route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
        case .recipe:
            return .recipe(recipe: nil)
        case let .recipeDetail(recipeID):
            guard let persistentIdentifier = try? PersistentModelStableIdentifierCodec.decode(
                recipeID
            ) else {
                return .recipe(recipe: nil)
            }
            let recipe = try context.fetchFirst(
                .recipes(.idIs(persistentIdentifier))
            )
            return .recipe(recipe: recipe)
        default:
            return .home
        }
    }

    private static func photoOutcome(
        for route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
        case .photo:
            return .photo(photo: nil)
        case let .photoDetail(photoID):
            guard let persistentIdentifier = try? PersistentModelStableIdentifierCodec.decode(
                photoID
            ) else {
                return .photo(photo: nil)
            }
            let photo = try context.fetchFirst(
                .photos(.idIs(persistentIdentifier))
            )
            return .photo(photo: photo)
        default:
            return .home
        }
    }

    private static func tagOutcome(
        for route: CookleRoute,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        switch route {
        case .tag(let kind):
            return tagListOutcome(for: kind)
        case let .tagDetail(kind, tagID):
            return try tagDetailOutcome(
                kind: kind,
                tagID: tagID,
                context: context
            )
        default:
            return .home
        }
    }

    private static func tagListOutcome(
        for kind: CookleTagRouteKind
    ) -> CookleRouteOutcome {
        switch kind {
        case .category:
            return .tagCategory(category: nil)
        case .ingredient:
            return .tagIngredient(ingredient: nil)
        }
    }

    private static func tagDetailOutcome(
        kind: CookleTagRouteKind,
        tagID: String,
        context: ModelContext
    ) throws -> CookleRouteOutcome {
        guard let persistentIdentifier = try? PersistentModelStableIdentifierCodec.decode(
            tagID
        ) else {
            return tagListOutcome(for: kind)
        }

        switch kind {
        case .category:
            let category = try context.fetchFirst(
                .categories(.idIs(persistentIdentifier))
            )
            return .tagCategory(category: category)
        case .ingredient:
            let ingredient = try context.fetchFirst(
                .ingredients(.idIs(persistentIdentifier))
            )
            return .tagIngredient(ingredient: ingredient)
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
