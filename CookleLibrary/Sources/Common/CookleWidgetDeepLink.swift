import Foundation

/// Widget destinations that can be opened from a widget tap.
public enum CookleWidgetDestination: String, Sendable {
    case diary
    case recipe
}

/// Deep-link helper shared by the app and widget extension.
public enum CookleWidgetDeepLink {
    /// Creates a deep-link URL for a widget destination.
    public static func url(for destination: CookleWidgetDestination) -> URL? {
        switch destination {
        case .diary:
            return CookleDeepLinkURLBuilder.diaryURL()
        case .recipe:
            return CookleDeepLinkURLBuilder.recipeURL()
        }
    }

    /// Extracts a widget destination from a deep-link URL.
    public static func destination(from deepLinkURL: URL) -> CookleWidgetDestination? {
        guard let route = CookleRouteParser.parse(url: deepLinkURL) else {
            return nil
        }
        switch route {
        case .diary,
             .diaryDate:
            return .diary
        case .recipe,
             .recipeDetail:
            return .recipe
        case .home,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense:
            return nil
        }
    }
}
