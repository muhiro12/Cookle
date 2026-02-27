import Foundation

/// Parses incoming URLs and maps them to app navigation routes.
public enum CookleRouteParser {
    public static let customScheme = CookleRouteURLDefaults.customScheme
    public static let universalLinkHosts: Set<String> = [
        CookleRouteURLDefaults.universalLinkHost
    ]

    public static func parse(
        url: URL,
        allowedUniversalLinkHosts: Set<String> = universalLinkHosts
    ) -> CookleRoute? {
        guard let scheme = url.scheme?.lowercased() else {
            return nil
        }

        let pathSegments: [String]
        switch scheme {
        case "http",
             "https":
            guard let host = url.host?.lowercased(),
                  allowedUniversalLinkHosts.contains(host) else {
                return nil
            }
            pathSegments = normalizedPathSegments(from: url.pathComponents)
        case customScheme:
            var normalizedSegments = [String]()
            if let host = url.host,
               host.isNotEmpty {
                normalizedSegments.append(host)
            }
            normalizedSegments.append(
                contentsOf: normalizedPathSegments(from: url.pathComponents)
            )
            pathSegments = normalizedSegments
        default:
            return nil
        }

        return route(
            from: pathSegments,
            queryItems: URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )?.queryItems ?? []
        )
    }
}

private extension CookleRouteParser {
    static func normalizedPathSegments(
        from pathComponents: [String]
    ) -> [String] {
        pathComponents.filter { pathComponent in
            pathComponent != "/"
        }
    }

    static func route(
        from pathSegments: [String],
        queryItems: [URLQueryItem]
    ) -> CookleRoute? {
        var normalizedSegments = pathSegments
        if normalizedSegments.first?.lowercased() ==
            CookleRouteURLDefaults.universalLinkPathPrefix.lowercased() {
            _ = normalizedSegments.removeFirst()
        }

        guard let destination = normalizedSegments.first?.lowercased() else {
            return .home
        }

        switch destination {
        case "home":
            guard normalizedSegments.count == 1 else {
                return nil
            }
            return .home
        case "diary":
            return parseDiaryRoute(
                from: Array(normalizedSegments.dropFirst())
            )
        case "recipe":
            return parseRecipeRoute(
                from: Array(normalizedSegments.dropFirst()),
                queryItems: queryItems
            )
        case "search":
            guard normalizedSegments.count == 1 else {
                return nil
            }
            let query = queryItems.first { queryItem in
                queryItem.name == "q"
            }?.value
            if let query,
               query.isNotEmpty {
                return .search(query: query)
            }
            return .search(query: nil)
        case "settings":
            guard normalizedSegments.count <= 2 else {
                return nil
            }
            guard normalizedSegments.count == 2 else {
                return .settings
            }
            switch normalizedSegments[1].lowercased() {
            case "subscription":
                return .settingsSubscription
            case "license":
                return .settingsLicense
            default:
                return nil
            }
        default:
            return nil
        }
    }

    static func parseDiaryRoute(
        from diarySegments: [String]
    ) -> CookleRoute? {
        guard diarySegments.count <= 1 else {
            return nil
        }
        guard let dateSegment = diarySegments.first else {
            return .diary
        }
        guard let dateRoute = parseDateRoute(from: dateSegment) else {
            return nil
        }
        return .diaryDate(
            year: dateRoute.year,
            month: dateRoute.month,
            day: dateRoute.day
        )
    }

    static func parseRecipeRoute(
        from recipeSegments: [String],
        queryItems: [URLQueryItem]
    ) -> CookleRoute? {
        guard recipeSegments.isEmpty else {
            return nil
        }
        guard let recipeID = queryItems.first(where: { queryItem in
            queryItem.name == "id"
        })?.value else {
            return .recipe
        }
        guard recipeID.isNotEmpty else {
            return nil
        }
        return .recipeDetail(recipeID)
    }

    static func parseDateRoute(from value: String) -> DateRoute? {
        let components = value.split(separator: "-")
        guard components.count == 3 else {
            return nil
        }
        let yearText = String(components[0])
        let monthText = String(components[1])
        let dayText = String(components[2])
        guard yearText.count == 4,
              monthText.count == 2,
              dayText.count == 2,
              let year = Int(yearText),
              let month = Int(monthText),
              let day = Int(dayText),
              1...9_999 ~= year,
              1...12 ~= month,
              1...31 ~= day else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .init(secondsFromGMT: 0)!
        let dateComponents = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        )
        guard let date = calendar.date(from: dateComponents) else {
            return nil
        }
        let resolved = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        guard resolved.year == year,
              resolved.month == month,
              resolved.day == day else {
            return nil
        }
        return .init(
            year: year,
            month: month,
            day: day
        )
    }

    struct DateRoute {
        let year: Int
        let month: Int
        let day: Int
    }
}
