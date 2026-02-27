import Foundation

/// Builds shareable URLs from app routes.
public enum CookleRouteURLBuilder {
    public static let customScheme = CookleRouteURLDefaults.customScheme
    public static let defaultUniversalLinkHost = CookleRouteURLDefaults.universalLinkHost
    public static let defaultUniversalLinkPathPrefix =
        CookleRouteURLDefaults.universalLinkPathPrefix

    public static func customSchemeURL(
        for route: CookleRoute
    ) -> URL? {
        let pathSegments = routePathSegments(route)
        var urlComponents = URLComponents()
        urlComponents.scheme = customScheme
        urlComponents.host = pathSegments.first
        if pathSegments.count >= 2 {
            urlComponents.path =
                "/" + pathSegments.dropFirst().joined(separator: "/")
        } else {
            urlComponents.path = .empty
        }
        urlComponents.queryItems = routeQueryItems(route)
        return urlComponents.url
    }

    public static func universalLinkURL(
        for route: CookleRoute,
        host: String = defaultUniversalLinkHost,
        appPathPrefix: String = defaultUniversalLinkPathPrefix
    ) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host

        var allPathSegments = [String]()
        if appPathPrefix.isNotEmpty {
            allPathSegments.append(appPathPrefix)
        }
        allPathSegments.append(contentsOf: routePathSegments(route))
        urlComponents.path = "/" + allPathSegments.joined(separator: "/")
        urlComponents.queryItems = routeQueryItems(route)
        return urlComponents.url
    }
}

private extension CookleRouteURLBuilder {
    static func routePathSegments(_ route: CookleRoute) -> [String] {
        switch route {
        case .home:
            return ["home"]
        case .diary:
            return ["diary"]
        case .diaryDate(let year, let month, let day):
            return [
                "diary",
                String(
                    format: "%04d-%02d-%02d",
                    year,
                    month,
                    day
                )
            ]
        case .recipe,
             .recipeDetail:
            return ["recipe"]
        case .search:
            return ["search"]
        case .settings:
            return ["settings"]
        case .settingsSubscription:
            return ["settings", "subscription"]
        case .settingsLicense:
            return ["settings", "license"]
        }
    }

    static func routeQueryItems(
        _ route: CookleRoute
    ) -> [URLQueryItem]? {
        switch route {
        case .recipeDetail(let recipeID):
            guard recipeID.isNotEmpty else {
                return nil
            }
            return [
                .init(
                    name: "id",
                    value: recipeID
                )
            ]
        case .search(let query):
            guard let query,
                  query.isNotEmpty else {
                return nil
            }
            return [
                .init(
                    name: "q",
                    value: query
                )
            ]
        case .home,
             .diary,
             .diaryDate,
             .recipe,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            return nil
        }
    }
}
