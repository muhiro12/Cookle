import Foundation
import MHDeepLinking

extension CookleRoute: MHDeepLinkRoute {
    private static let dateComponentCount = 3
    private static let yearComponentIndex = 0
    private static let monthComponentIndex = 1
    private static let dayComponentIndex = 2
    private static let yearTextCount = 4
    private static let monthTextCount = 2
    private static let dayTextCount = 2

    public var deepLinkDescriptor: MHDeepLinkDescriptor {
        switch self {
        case .home:
            .init(pathComponents: ["home"])
        case .diary:
            .init(pathComponents: ["diary"])
        case let .diaryDate(year, month, day):
            .init(
                pathComponents: [
                    "diary",
                    String(format: "%04d-%02d-%02d", year, month, day)
                ]
            )
        case .recipe:
            .init(pathComponents: ["recipe"])
        case .recipeDetail(let recipeID):
            .init(
                pathComponents: ["recipe"],
                queryItems: recipeID.isNotEmpty ? [
                    .init(name: "id", value: recipeID)
                ] : []
            )
        case .search(let query):
            .init(
                pathComponents: ["search"],
                queryItems: query?.isNotEmpty == true ? [
                    .init(name: "q", value: query)
                ] : []
            )
        case .settings:
            .init(pathComponents: ["settings"])
        case .settingsSubscription:
            .init(pathComponents: ["settings", "subscription"])
        case .settingsLicense:
            .init(pathComponents: ["settings", "license"])
        }
    }

    public init?(deepLinkDescriptor: MHDeepLinkDescriptor) {
        let pathComponents = deepLinkDescriptor.pathComponents
        let queryItems = deepLinkDescriptor.queryItems

        guard let destination = pathComponents.first?.lowercased() else {
            self = .home
            return
        }

        guard let route = Self.parseRoute(
            destination: destination,
            pathComponents: pathComponents,
            queryItems: queryItems
        ) else {
            return nil
        }
        self = route
    }

    private static func parseRoute(
        destination: String,
        pathComponents: [String],
        queryItems: [URLQueryItem]
    ) -> CookleRoute? {
        switch destination {
        case "home":
            guard pathComponents.count == 1 else {
                return nil
            }
            return .home
        case "diary":
            return Self.parseDiaryRoute(
                from: Array(pathComponents.dropFirst())
            )
        case "recipe":
            return Self.parseRecipeRoute(
                from: Array(pathComponents.dropFirst()),
                queryItems: queryItems
            )
        case "search":
            guard pathComponents.count == 1 else {
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
            return Self.parseSettingsRoute(from: pathComponents)
        default:
            return nil
        }
    }

    private static func parseSettingsRoute(from pathComponents: [String]) -> CookleRoute? {
        guard pathComponents.count <= 2 else { // swiftlint:disable:this no_magic_numbers
            return nil
        }
        guard pathComponents.count == 2 else { // swiftlint:disable:this no_magic_numbers
            return .settings
        }
        switch pathComponents[1].lowercased() {
        case "subscription":
            return .settingsSubscription
        case "license":
            return .settingsLicense
        default:
            return nil
        }
    }

    private static func parseDiaryRoute(from segments: [String]) -> CookleRoute? {
        guard segments.count <= 1 else {
            return nil
        }
        guard let dateSegment = segments.first else {
            return .diary
        }
        guard let dateComponents = parseDateRoute(from: dateSegment) else {
            return nil
        }
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day else {
            return nil
        }
        return .diaryDate(
            year: year,
            month: month,
            day: day
        )
    }

    private static func parseRecipeRoute(
        from segments: [String],
        queryItems: [URLQueryItem]
    ) -> CookleRoute? {
        guard segments.isEmpty else {
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

    private static func parseDateRoute(from value: String) -> DateComponents? {
        let components = value.split(separator: "-")
        guard components.count == Self.dateComponentCount else {
            return nil
        }

        let yearText = String(components[Self.yearComponentIndex])
        let monthText = String(components[Self.monthComponentIndex])
        let dayText = String(components[Self.dayComponentIndex])
        guard yearText.count == Self.yearTextCount,
              monthText.count == Self.monthTextCount,
              dayText.count == Self.dayTextCount,
              let year = Int(yearText),
              let month = Int(monthText),
              let day = Int(dayText),
              1...9_999 ~= year, // swiftlint:disable:this no_magic_numbers
              1...12 ~= month, // swiftlint:disable:this no_magic_numbers
              1...31 ~= day else { // swiftlint:disable:this no_magic_numbers
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
