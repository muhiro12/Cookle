import Foundation

/// Builds deep-link URLs used by external entry points.
public enum CookleDeepLinkURLBuilder {
    /// Returns the universal-link form of the supplied route when possible.
    public static func routeURL(for route: CookleRoute) -> URL? {
        CookleRouteURLBuilder.universalLinkURL(for: route)
    }

    /// Returns the preferred shareable URL for the supplied route.
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
        return URL(
            string: "\(CookleRouteURLDefaults.customScheme)://home"
        ) ?? .temporaryDirectory
    }

    /// Returns the home route as a universal link.
    public static func homeURL() -> URL? {
        routeURL(for: .home)
    }

    /// Returns the preferred URL for the home route.
    public static func preferredHomeURL() -> URL {
        preferredURL(for: .home)
    }

    /// Returns the diary list route as a universal link.
    public static func diaryURL() -> URL? {
        routeURL(for: .diary)
    }

    /// Returns the preferred URL for the diary list route.
    public static func preferredDiaryURL() -> URL {
        preferredURL(for: .diary)
    }

    /// Returns a diary-detail URL for the supplied date.
    public static func diaryURL(
        for date: Date,
        calendar: Calendar = .current
    ) -> URL? {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return routeURL(for: .diaryDate(year: year, month: month, day: day))
    }

    /// Returns the preferred diary-detail URL for the supplied date.
    public static func preferredDiaryURL(
        for date: Date,
        calendar: Calendar = .current
    ) -> URL {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return preferredURL(for: .diaryDate(year: year, month: month, day: day))
    }

    /// Returns the recipe list route as a universal link.
    public static func recipeURL() -> URL? {
        routeURL(for: .recipe)
    }

    /// Returns the preferred URL for the recipe list route.
    public static func preferredRecipeURL() -> URL {
        preferredURL(for: .recipe)
    }

    /// Returns a recipe-detail URL for the supplied recipe identifier.
    public static func recipeDetailURL(for recipeID: String) -> URL? {
        routeURL(for: .recipeDetail(recipeID))
    }

    /// Returns the preferred recipe-detail URL for the supplied recipe identifier.
    public static func preferredRecipeDetailURL(for recipeID: String) -> URL {
        preferredURL(for: .recipeDetail(recipeID))
    }

    /// Returns a search URL for the supplied query text.
    public static func searchURL(query: String?) -> URL? {
        routeURL(for: .search(query: query))
    }

    /// Returns the preferred search URL for the supplied query text.
    public static func preferredSearchURL(query: String?) -> URL {
        preferredURL(for: .search(query: query))
    }
}
