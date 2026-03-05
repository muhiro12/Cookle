import Foundation

/// Parses incoming URLs and maps them to app navigation routes.
public enum CookleRouteParser {
    /// Custom URL scheme accepted by the parser.
    public static let customScheme = CookleRouteURLDefaults.customScheme
    /// Universal-link hosts accepted by the parser.
    public static let universalLinkHosts: Set<String> = [
        CookleRouteURLDefaults.universalLinkHost
    ]

    /// Parses a URL into a route understood by the app.
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
    enum ParseConstants {
        static let settingsPathSegmentLimit = Int("2") ?? .zero
        static let settingsPathSegmentCount = Int("2") ?? .zero
        static let dateSegmentCount = Int("3") ?? .zero
        static let yearSegmentIndex = Int("0") ?? .zero
        static let monthSegmentIndex = Int("1") ?? .zero
        static let daySegmentIndex = Int("2") ?? .zero
        static let yearTextLength = Int("4") ?? .zero
        static let monthDayTextLength = Int("2") ?? .zero
        static let minimumDateComponent = Int("1") ?? .zero
        static let maximumYear = Int("9999") ?? .zero
        static let maximumMonth = Int("12") ?? .zero
        static let maximumDay = Int("31") ?? .zero
    }

    struct DateRoute {
        let year: Int
        let month: Int
        let day: Int
    }

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
        let normalizedSegments = normalizedSegments(from: pathSegments)

        guard let destination = normalizedSegments.first?.lowercased() else {
            return .home
        }

        switch destination {
        case "home":
            return parseHomeRoute(from: normalizedSegments)
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
            return parseSearchRoute(
                from: normalizedSegments,
                queryItems: queryItems
            )
        case "settings":
            return parseSettingsRoute(from: normalizedSegments)
        default:
            return nil
        }
    }

    static func normalizedSegments(from pathSegments: [String]) -> [String] {
        var normalizedSegments = pathSegments
        if normalizedSegments.first?.lowercased() ==
            CookleRouteURLDefaults.universalLinkPathPrefix.lowercased() {
            _ = normalizedSegments.removeFirst()
        }
        return normalizedSegments
    }

    static func parseHomeRoute(from normalizedSegments: [String]) -> CookleRoute? {
        guard normalizedSegments.count == 1 else {
            return nil
        }
        return .home
    }

    static func parseSearchRoute(
        from normalizedSegments: [String],
        queryItems: [URLQueryItem]
    ) -> CookleRoute? {
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
    }

    static func parseSettingsRoute(from normalizedSegments: [String]) -> CookleRoute? {
        guard normalizedSegments.count <= ParseConstants.settingsPathSegmentLimit else {
            return nil
        }
        guard normalizedSegments.count == ParseConstants.settingsPathSegmentCount else {
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
        guard components.count == ParseConstants.dateSegmentCount else {
            return nil
        }
        let yearText = String(components[ParseConstants.yearSegmentIndex])
        let monthText = String(components[ParseConstants.monthSegmentIndex])
        let dayText = String(components[ParseConstants.daySegmentIndex])
        guard yearText.count == ParseConstants.yearTextLength,
              monthText.count == ParseConstants.monthDayTextLength,
              dayText.count == ParseConstants.monthDayTextLength,
              let year = Int(yearText),
              let month = Int(monthText),
              let day = Int(dayText),
              ParseConstants.minimumDateComponent...ParseConstants.maximumYear ~= year,
              ParseConstants.minimumDateComponent...ParseConstants.maximumMonth ~= month,
              ParseConstants.minimumDateComponent...ParseConstants.maximumDay ~= day else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: .zero) ?? .current
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
}
