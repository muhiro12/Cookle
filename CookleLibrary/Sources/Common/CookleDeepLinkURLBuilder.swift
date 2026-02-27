import Foundation

/// Builds deep-link URLs used by external entry points.
public enum CookleDeepLinkURLBuilder {
    public static func routeURL(for route: CookleRoute) -> URL? {
        CookleRouteURLBuilder.universalLinkURL(for: route)
    }

    public static func preferredURL(for route: CookleRoute) -> URL {
        if let universalLinkURL = routeURL(for: route) {
            return universalLinkURL
        }
        if let customSchemeURL = CookleRouteURLBuilder.customSchemeURL(for: route) {
            return customSchemeURL
        }
        if let homeCustomSchemeURL =
            CookleRouteURLBuilder.customSchemeURL(for: .home) {
            return homeCustomSchemeURL
        }
        return .init(
            string: "\(CookleRouteURLDefaults.customScheme)://home"
        )!
    }

    public static func homeURL() -> URL? {
        routeURL(for: .home)
    }

    public static func preferredHomeURL() -> URL {
        preferredURL(for: .home)
    }

    public static func diaryURL() -> URL? {
        routeURL(for: .diary)
    }

    public static func preferredDiaryURL() -> URL {
        preferredURL(for: .diary)
    }

    public static func diaryURL(
        for date: Date,
        calendar: Calendar = .current
    ) -> URL? {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return routeURL(for: .diaryDate(year: year, month: month, day: day))
    }

    public static func preferredDiaryURL(
        for date: Date,
        calendar: Calendar = .current
    ) -> URL {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return preferredURL(for: .diaryDate(year: year, month: month, day: day))
    }

    public static func recipeURL() -> URL? {
        routeURL(for: .recipe)
    }

    public static func preferredRecipeURL() -> URL {
        preferredURL(for: .recipe)
    }

    public static func recipeDetailURL(for recipeID: String) -> URL? {
        routeURL(for: .recipeDetail(recipeID))
    }

    public static func preferredRecipeDetailURL(for recipeID: String) -> URL {
        preferredURL(for: .recipeDetail(recipeID))
    }

    public static func searchURL(query: String?) -> URL? {
        routeURL(for: .search(query: query))
    }

    public static func preferredSearchURL(query: String?) -> URL {
        preferredURL(for: .search(query: query))
    }
}
